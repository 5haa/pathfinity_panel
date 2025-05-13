import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/gift_card_model.dart';
import 'package:admin_panel/services/gift_card_service.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final giftCardServiceProvider = Provider<GiftCardService>(
  (ref) => GiftCardService(),
);

class GiftCardManagementScreen extends ConsumerStatefulWidget {
  const GiftCardManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GiftCardManagementScreen> createState() =>
      _GiftCardManagementScreenState();
}

class _GiftCardManagementScreenState
    extends ConsumerState<GiftCardManagementScreen> {
  bool _isLoading = true;
  List<GiftCard> _giftCards = [];
  GiftCardStats? _stats;
  bool _isCreatingGiftCard = false;

  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _daysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGiftCards();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _loadGiftCards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final giftCardService = ref.read(giftCardServiceProvider);
      final giftCards = await giftCardService.getAllGiftCards();
      final stats = await giftCardService.getGiftCardStats();

      setState(() {
        _giftCards = giftCards;
        _stats = stats;
      });
    } catch (e) {
      debugPrint('Error loading gift cards: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateGiftCardForm() {
    _notesController.clear();
    _daysController.clear();
    setState(() {
      _isCreatingGiftCard = true;
    });
  }

  void _cancelForm() {
    setState(() {
      _isCreatingGiftCard = false;
    });
  }

  Future<void> _createGiftCard() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('Gift card form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Starting gift card creation process');
      final giftCardService = ref.read(giftCardServiceProvider);

      int? days;
      if (_daysController.text.isNotEmpty) {
        days = int.tryParse(_daysController.text);
        debugPrint(
          'Parsed days value: $days from text: ${_daysController.text}',
        );
      } else {
        debugPrint('No days value provided');
      }

      debugPrint(
        'Calling createGiftCard with days: $days, metadata: ${_notesController.text.trim()}',
      );
      final newGiftCard = await giftCardService.createGiftCard(
        days: days,
        notes: _notesController.text.trim(),
        quantity: 1,
      );
      debugPrint('createGiftCard response: ${newGiftCard?.toJson()}');

      if (newGiftCard != null && mounted) {
        debugPrint('Gift card created successfully: ${newGiftCard.code}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gift card created successfully: ${newGiftCard.code}',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _cancelForm();
        await _loadGiftCards();
      } else if (mounted) {
        debugPrint('Gift card creation failed: newGiftCard is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create gift card'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating gift card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testUseGiftCard(String code) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final giftCardService = ref.read(giftCardServiceProvider);
      final success = await giftCardService.useGiftCard(code);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gift card used successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _loadGiftCards();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to use gift card'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error using gift card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Card Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            GoRouter.of(context).go('/admin');
          },
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsSection(),
                          const SizedBox(height: 24),
                          if (_isCreatingGiftCard) _buildGiftCardForm(),
                          if (!_isCreatingGiftCard)
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'All Gift Cards',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        Text(
                                          'Total: ${_giftCards.length}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 32),
                                    _buildGiftCardList(),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton:
          !_isCreatingGiftCard
              ? FloatingActionButton(
                onPressed: _showCreateGiftCardForm,
                backgroundColor: AppTheme.accentColor,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gift Card Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create and manage gift cards for your courses',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (!_isCreatingGiftCard)
                CustomButton(
                  text: 'Create Gift Card',
                  onPressed: _showCreateGiftCardForm,
                  icon: Icons.add,
                  type: ButtonType.outline,
                  height: 40,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_stats == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gift Card Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  'Total',
                  _stats!.totalCards.toString(),
                  Icons.card_giftcard,
                  AppTheme.primaryColor,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Used',
                  _stats!.usedCards.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Available',
                  _stats!.unusedCards.toString(),
                  Icons.new_releases,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftCardForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Gift Card',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Days (Optional)',
                controller: _daysController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final number = int.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Please enter a valid positive number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Notes (Optional)',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    text: 'Cancel',
                    onPressed: _cancelForm,
                    type: ButtonType.secondary,
                    height: 42,
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    text: 'Generate Gift Card',
                    onPressed: _createGiftCard,
                    isLoading: _isLoading,
                    type: ButtonType.primary,
                    height: 42,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGiftCardList() {
    if (_giftCards.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.card_giftcard, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No gift cards found',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textLightColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Create your first gift card to get started',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _giftCards.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final giftCard = _giftCards[index];

        Color statusColor;
        String statusText;

        if (giftCard.redeemedAt != null) {
          statusColor = Colors.grey;
          statusText = 'Used';
        } else {
          statusColor = AppTheme.successColor;
          statusText = 'Available';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              giftCard.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: giftCard.code),
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Code copied to clipboard'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                              child: const Icon(
                                Icons.copy,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            Text(
                              'Created: ${DateFormat('MMM dd, yyyy').format(giftCard.createdAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (giftCard.days != null)
                              Text(
                                '• Days: ${giftCard.days}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        FutureBuilder<String>(
                          future: _getAdminName(giftCard.generatedBy),
                          builder: (context, snapshot) {
                            return Text(
                              'Generated by: ${snapshot.data ?? "Unknown"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (giftCard.metadata.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 52, top: 4),
                  child: Text(
                    'Notes: ${giftCard.metadata}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to get admin name from ID
  Future<String> _getAdminName(String? adminId) async {
    if (adminId == null) return "Unknown";

    try {
      final data =
          await Supabase.instance.client
              .from('user_admins')
              .select('first_name, last_name')
              .eq('id', adminId)
              .single();

      if (data != null) {
        final firstName = data['first_name'] ?? '';
        final lastName = data['last_name'] ?? '';
        return '$firstName $lastName'.trim();
      }
    } catch (e) {
      debugPrint('Error fetching admin details: $e');
    }

    return adminId.substring(0, 8) + '...'; // Fallback to truncated ID
  }
}
