import 'dart:io';
import 'package:flutter/material.dart'; // Kept for debugPrint, can be removed if not used elsewhere
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/models/course_video_model.dart'; // Import the new model
import 'package:admin_panel/models/video_change_model.dart'; // Import the video change model
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added Riverpod
import 'package:uuid/uuid.dart';

// Provider for CourseVideoService
final courseVideoServiceProvider = Provider<CourseVideoService>((ref) {
  return CourseVideoService();
});

// UUID generator for unique filenames
final _uuid = Uuid();

class CourseVideoService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _videoBucketName = 'course-videos';
  final String _thumbnailBucketName = 'video-thumbnails';

  // Add a video to a course
  Future<CourseVideo?> addCourseVideo({
    required String courseId,
    required String title,
    required String description,
    required String videoUrl,
    String? thumbnailUrl,
    required int sequenceNumber,
    bool isFreePreview = false,
  }) async {
    try {
      final response =
          await _supabase
              .from('course_videos')
              .insert({
                'course_id': courseId,
                'title': title,
                'description': description,
                'video_url': videoUrl,
                'thumbnail_url': thumbnailUrl,
                'sequence_number': sequenceNumber,
                'is_reviewed': false,
                'is_free_preview': isFreePreview,
                // 'is_approved': null, // Handled by DB default or nullable
                // 'rejection_reason': null, // Handled by DB default or nullable
              })
              .select()
              .single();
      return CourseVideo.fromJson(response);
    } catch (e) {
      debugPrint('Error adding course video: $e');
      return null;
    }
  }

  // Get videos for a course
  Future<List<CourseVideo>> getCourseVideos(String courseId) async {
    try {
      final data = await _supabase
          .from('course_videos')
          .select()
          .eq('course_id', courseId)
          .order('sequence_number');
      return data.map((item) => CourseVideo.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error getting course videos: $e');
      return [];
    }
  }

  // Update a course video
  Future<bool> updateCourseVideo({
    required String videoId,
    required String title,
    required String description,
    required String videoUrl,
    String? thumbnailUrl,
    bool? isFreePreview,
    // Include other updatable fields from the model if needed
    bool? isReviewed,
    bool? isApproved,
    String? rejectionReason,
  }) async {
    try {
      final updateData = {
        'title': title,
        'description': description,
        'video_url': videoUrl,
        // Reset approval status when video is updated by content creator as per original logic
        'is_reviewed': isReviewed ?? false,
        'is_approved': isApproved, // Explicitly set or allow null
        'rejection_reason': rejectionReason, // Explicitly set or allow null
      };

      // Only include these fields if they are provided
      if (thumbnailUrl != null) {
        updateData['thumbnail_url'] = thumbnailUrl;
      }

      if (isFreePreview != null) {
        updateData['is_free_preview'] = isFreePreview;
      }

      await _supabase
          .from('course_videos')
          .update(updateData)
          .eq('id', videoId);
      return true;
    } catch (e) {
      debugPrint('Error updating course video: $e');
      return false;
    }
  }

  // Delete a course video
  Future<bool> deleteCourseVideo(String videoId) async {
    try {
      await _supabase.from('course_videos').delete().eq('id', videoId);
      return true;
    } catch (e) {
      debugPrint('Error deleting course video: $e');
      return false;
    }
  }

  // Update video sequence numbers
  Future<bool> updateVideoSequence(
    String
    courseId, // courseId might not be strictly needed if video IDs are globally unique and RPC handles it
    List<Map<String, dynamic>>
    videoSequences, // Consider using a list of CourseVideo objects or specific sequence update model
  ) async {
    try {
      // Use a transaction to update all videos atomically
      await _supabase.rpc(
        'update_video_sequences', // Ensure this RPC exists and matches parameters
        params: {'video_data': videoSequences},
      );
      return true;
    } catch (e) {
      // Fallback to individual updates if RPC fails or doesn't exist
      debugPrint(
        'RPC update_video_sequences failed: $e. Falling back to individual updates.',
      );
      try {
        for (final videoUpdate in videoSequences) {
          // videoUpdate should be Map<String, dynamic> {'id': X, 'sequence_number': Y}
          await _supabase
              .from('course_videos')
              .update({'sequence_number': videoUpdate['sequence_number']})
              .eq('id', videoUpdate['id']);
          // .eq('course_id', courseId); // Add if videos are only unique within a course
        }
        return true;
      } catch (innerE) {
        debugPrint('Error updating video sequences individually: $innerE');
        return false;
      }
    }
  }

  // Upload a video file to Supabase storage
  Future<String?> uploadVideo(
    File videoFile,
    String creatorIdOrPathPrefix,
  ) async {
    // creatorIdOrPathPrefix is used for path generation
    try {
      final fileExtension = path.extension(videoFile.path);
      final fileName =
          'video_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = 'videos/$creatorIdOrPathPrefix/$fileName';

      if (!await videoFile.exists()) {
        debugPrint(
          'Error: The source video file does not exist at path: ${videoFile.path}',
        );
        return null;
      }

      try {
        await _supabase.storage
            .from(_videoBucketName)
            .upload(filePath, videoFile);
      } on StorageException catch (e) {
        debugPrint(
          'StorageException during upload: ${e.message}, StatusCode: ${e.statusCode}',
        );
        if (e.statusCode == '404' && e.message.contains('Bucket not found')) {
          debugPrint(
            'The storage bucket "$_videoBucketName" does not exist. Please create it in your Supabase dashboard.',
          );
        }
        return null;
      }

      // Return the public URL for the uploaded file
      final String publicUrl = _supabase.storage
          .from(_videoBucketName)
          .getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading video: $e');
      return null;
    }
  }

  // Upload a thumbnail image to Supabase storage
  Future<String?> uploadThumbnail(
    File thumbnailFile,
    String creatorIdOrPathPrefix,
  ) async {
    try {
      final fileExtension = path.extension(thumbnailFile.path);
      final fileName = 'thumbnail_${_uuid.v4()}$fileExtension';
      final filePath = '$creatorIdOrPathPrefix/$fileName';

      if (!await thumbnailFile.exists()) {
        debugPrint(
          'Error: The source thumbnail file does not exist at path: ${thumbnailFile.path}',
        );
        return null;
      }

      try {
        await _supabase.storage
            .from(_thumbnailBucketName)
            .upload(
              filePath,
              thumbnailFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
      } on StorageException catch (e) {
        debugPrint(
          'StorageException during thumbnail upload: ${e.message}, StatusCode: ${e.statusCode}',
        );
        if (e.statusCode == '404' && e.message.contains('Bucket not found')) {
          debugPrint(
            'The storage bucket "$_thumbnailBucketName" does not exist. Please create it in your Supabase dashboard.',
          );
        }
        return null;
      }

      // Return the public URL for the uploaded thumbnail
      final String publicUrl = _supabase.storage
          .from(_thumbnailBucketName)
          .getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading thumbnail: $e');
      return null;
    }
  }

  // Helper to delete video from storage
  Future<bool> deleteVideoFromStorage(String videoUrl) async {
    // Changed parameter to videoUrl
    if (videoUrl.isEmpty || !Uri.parse(videoUrl).isAbsolute) {
      debugPrint('Invalid or empty video URL for deletion: $videoUrl');
      return false;
    }
    try {
      // Extract path from URL
      final uri = Uri.parse(videoUrl);
      // Example URL: https://<project-ref>.supabase.co/storage/v1/object/public/course_videos/videos/creator_id/video.mp4
      // We need the path after the bucket name: videos/creator_id/video.mp4
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(_videoBucketName);

      if (bucketIndex == -1 || bucketIndex + 1 >= pathSegments.length) {
        debugPrint('Could not extract path from video URL: $videoUrl');
        return false;
      }
      final String filePathInBucket = pathSegments
          .sublist(bucketIndex + 1)
          .join('/');

      await _supabase.storage.from(_videoBucketName).remove([filePathInBucket]);
      return true;
    } catch (e) {
      debugPrint('Error deleting video from storage ($videoUrl): $e');
      return false;
    }
  }

  // Helper to delete thumbnail from storage
  Future<bool> deleteThumbnailFromStorage(String thumbnailUrl) async {
    if (thumbnailUrl.isEmpty || !Uri.parse(thumbnailUrl).isAbsolute) {
      debugPrint('Invalid or empty thumbnail URL for deletion: $thumbnailUrl');
      return false;
    }
    try {
      // Extract path from URL
      final uri = Uri.parse(thumbnailUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(_thumbnailBucketName);

      if (bucketIndex == -1 || bucketIndex + 1 >= pathSegments.length) {
        debugPrint('Could not extract path from thumbnail URL: $thumbnailUrl');
        return false;
      }
      final String filePathInBucket = pathSegments
          .sublist(bucketIndex + 1)
          .join('/');

      await _supabase.storage.from(_thumbnailBucketName).remove([
        filePathInBucket,
      ]);
      return true;
    } catch (e) {
      debugPrint('Error deleting thumbnail from storage ($thumbnailUrl): $e');
      return false;
    }
  }

  // Add a video to a course with file upload
  Future<CourseVideo?> addCourseVideoWithFile({
    required String courseId,
    required String title,
    required String description,
    required File videoFile,
    File? thumbnailFile,
    required int sequenceNumber,
    bool isFreePreview = false,
    required String
    creatorId, // Used for organizing video files by creatorId in storage
  }) async {
    // Upload video file
    final String? uploadedVideoUrl = await uploadVideo(videoFile, creatorId);

    if (uploadedVideoUrl == null) {
      debugPrint('Video upload failed. Cannot add course video.');
      return null;
    }

    // Upload thumbnail if provided
    String? uploadedThumbnailUrl;
    if (thumbnailFile != null) {
      uploadedThumbnailUrl = await uploadThumbnail(thumbnailFile, creatorId);

      if (uploadedThumbnailUrl == null) {
        debugPrint(
          'Thumbnail upload failed, but continuing with video creation.',
        );
      }
    }

    try {
      final newVideo = await addCourseVideo(
        courseId: courseId,
        title: title,
        description: description,
        videoUrl: uploadedVideoUrl, // Store the public URL
        thumbnailUrl: uploadedThumbnailUrl,
        sequenceNumber: sequenceNumber,
        isFreePreview: isFreePreview,
      );
      return newVideo;
    } catch (e) {
      debugPrint('Error adding course video db record: $e');
      await deleteVideoFromStorage(uploadedVideoUrl);

      if (uploadedThumbnailUrl != null) {
        await deleteThumbnailFromStorage(uploadedThumbnailUrl);
      }

      return null;
    }
  }

  // Update a course video with file upload
  Future<bool> updateCourseVideoWithFile({
    required String videoId,
    required String title,
    required String description,
    File? newVideoFile,
    File? newThumbnailFile,
    bool? isFreePreview,
    required String creatorId, // For path if new video is uploaded
    String? currentVideoUrl, // FULL URL of the existing video in storage
    String?
    currentThumbnailUrl, // FULL URL of the existing thumbnail in storage
  }) async {
    String finalVideoUrl = currentVideoUrl ?? '';
    String? finalThumbnailUrl = currentThumbnailUrl;

    // Handle video file update if provided
    if (newVideoFile != null) {
      final String? newUploadedVideoUrl = await uploadVideo(
        newVideoFile,
        creatorId,
      );

      if (newUploadedVideoUrl == null) {
        debugPrint('New video upload failed. Cannot update course video.');
        return false;
      }
      finalVideoUrl = newUploadedVideoUrl;

      if (currentVideoUrl != null && currentVideoUrl.isNotEmpty) {
        await deleteVideoFromStorage(currentVideoUrl);
      }
    }

    // Handle thumbnail file update if provided
    if (newThumbnailFile != null) {
      final String? newUploadedThumbnailUrl = await uploadThumbnail(
        newThumbnailFile,
        creatorId,
      );

      if (newUploadedThumbnailUrl == null) {
        debugPrint(
          'New thumbnail upload failed, but continuing with video update.',
        );
      } else {
        finalThumbnailUrl = newUploadedThumbnailUrl;

        if (currentThumbnailUrl != null && currentThumbnailUrl.isNotEmpty) {
          await deleteThumbnailFromStorage(currentThumbnailUrl);
        }
      }
    }

    try {
      return await updateCourseVideo(
        videoId: videoId,
        title: title,
        description: description,
        videoUrl: finalVideoUrl,
        thumbnailUrl: finalThumbnailUrl,
        isFreePreview: isFreePreview,
      );
    } catch (e) {
      debugPrint('Error updating course video db record: $e');
      return false;
    }
  }

  // Delete a course video and its file from storage
  Future<bool> deleteCourseVideoWithFile({
    required String videoId,
    required String videoUrl, // FULL URL of the video in storage
    String? thumbnailUrl, // FULL URL of the thumbnail in storage
  }) async {
    try {
      bool deletedVideoFromStorage = true;
      bool deletedThumbnailFromStorage = true;

      if (videoUrl.isNotEmpty) {
        deletedVideoFromStorage = await deleteVideoFromStorage(videoUrl);
      }

      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        deletedThumbnailFromStorage = await deleteThumbnailFromStorage(
          thumbnailUrl,
        );
      }

      if (!deletedVideoFromStorage) {
        debugPrint(
          'Failed to delete video from storage, but proceeding to delete DB record.',
        );
      }

      if (!deletedThumbnailFromStorage) {
        debugPrint(
          'Failed to delete thumbnail from storage, but proceeding to delete DB record.',
        );
      }

      final deletedFromDb = await deleteCourseVideo(videoId);
      return deletedFromDb;
    } catch (e) {
      debugPrint('Error deleting course video with file: $e');
      return false;
    }
  }

  // Request video changes
  Future<bool> requestVideoChanges({
    required String courseVideoId,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    bool? isFreePreview,
  }) async {
    try {
      // Ensure at least one field is being changed
      if (title == null &&
          description == null &&
          videoUrl == null &&
          thumbnailUrl == null &&
          isFreePreview == null) {
        debugPrint('No changes provided for video change request');
        return false;
      }

      await _supabase.from('video_changes').insert({
        'course_video_id': courseVideoId,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (videoUrl != null) 'video_url': videoUrl,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (isFreePreview != null) 'is_free_preview': isFreePreview,
      });
      return true;
    } catch (e) {
      debugPrint('Error requesting video changes: $e');
      return false;
    }
  }

  // Request video changes with file upload
  Future<bool> requestVideoChangesWithFile({
    required String courseVideoId,
    String? title,
    String? description,
    File? newVideoFile,
    File? newThumbnailFile,
    bool? isFreePreview,
    required String creatorId,
  }) async {
    String? uploadedVideoUrl;
    String? uploadedThumbnailUrl;

    // Upload video if provided
    if (newVideoFile != null) {
      uploadedVideoUrl = await uploadVideo(newVideoFile, creatorId);
      if (uploadedVideoUrl == null) {
        debugPrint('Video upload failed. Cannot request video changes.');
        return false;
      }
    }

    // Upload thumbnail if provided
    if (newThumbnailFile != null) {
      uploadedThumbnailUrl = await uploadThumbnail(newThumbnailFile, creatorId);
      if (uploadedThumbnailUrl == null) {
        // Continue even if thumbnail upload fails
        debugPrint(
          'Thumbnail upload failed, but continuing with video change request',
        );
      }
    }

    // Request changes
    return requestVideoChanges(
      courseVideoId: courseVideoId,
      title: title,
      description: description,
      videoUrl: uploadedVideoUrl,
      thumbnailUrl: uploadedThumbnailUrl,
      isFreePreview: isFreePreview,
    );
  }
}
