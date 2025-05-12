import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/gift_card_model.dart';
import 'package:admin_panel/services/gift_card_service.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';

final giftCardServiceProvider = Provider<GiftCardService>(
  (ref) => GiftCardService(),
);

class GiftCardManagementTab extends ConsumerStatefulWidget {
  const GiftCardManagementTab({Key? key}) : super(key: key);

  @override
  ConsumerState<GiftCardManagementTab> createState() =>
      _GiftCardManagementTabState();
}

class _GiftCardManagementTabState extends ConsumerState<GiftCardManagementTab> {
  bool _isLoading = true;
  List<GiftCard> _giftCards = [];
  GiftCardStats? _stats;
  bool _isCreatingGiftCard = false;

  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _loadGiftCards();
  }

  @override
  void dispose() {
    _notesController.dispose();
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
    _expiryDate = null;
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
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final giftCardService = ref.read(giftCardServiceProvider);

      final newGiftCard = await giftCardService.createGiftCard(
        expiresAt: _expiryDate,
        notes: _notesController.text.trim(),
      );

      if (newGiftCard != null && mounted) {
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gift Card Management',
                    style: AppTheme.subheadingStyle,
                  ),
                  if (!_isCreatingGiftCard)
                    CustomButton(
                      text: 'Create Gift Card',
                      onPressed: _showCreateGiftCardForm,
                      icon: Icons.add,
                      type: ButtonType.primary,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_stats != null) _buildStatsCards(),
              const SizedBox(height: 24),
              if (_isCreatingGiftCard) _buildGiftCardForm(),
              if (!_isCreatingGiftCard) ...[
                const Text('Gift Cards', style: AppTheme.subheadingStyle),
                const SizedBox(height: 16),
                if (_giftCards.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No gift cards found.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textLightColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                else
                  _buildGiftCardsList(),
              ],
            ],
          ),
        );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Cards',
            value: _stats!.totalCards.toString(),
            subtitle: '${_stats!.totalCards} cards total',
            icon: Icons.card_giftcard,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Used Cards',
            value: _stats!.usedCards.toString(),
            subtitle: '${_stats!.usedCards} cards used',
            icon: Icons.check_circle,
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Unused Cards',
            value: _stats!.unusedCards.toString(),
            subtitle: '${_stats!.unusedCards} cards available',
            icon: Icons.pending,
            color: AppTheme.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftCardForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() {
                      _expiryDate = date;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: CustomTextField(
                    label: 'Expiry Date (Optional)',
                    controller: TextEditingController(
                      text:
                          _expiryDate != null
                              ? DateFormat('yyyy-MM-dd').format(_expiryDate!)
                              : '',
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixIcon:
                        _expiryDate != null
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _expiryDate = null;
                                });
                              },
                            )
                            : null,
                  ),
                ),
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
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    text: 'Create',
                    onPressed: _createGiftCard,
                    isLoading: _isLoading,
                    type: ButtonType.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGiftCardsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _giftCards.length,
      itemBuilder: (context, index) {
        final giftCard = _giftCards[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Row(
              children: [
                Icon(
                  giftCard.isUsed ? Icons.check_circle : Icons.card_giftcard,
                  color:
                      giftCard.isUsed
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        giftCard.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            trailing: Chip(
              label: Text(
                giftCard.isUsed ? 'Used' : 'Available',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor:
                  giftCard.isUsed
                      ? AppTheme.successColor
                      : AppTheme.primaryColor,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Created',
                      DateFormat('yyyy-MM-dd HH:mm').format(giftCard.createdAt),
                    ),
                    if (giftCard.expiresAt != null)
                      _buildInfoRow(
                        'Expires',
                        DateFormat('yyyy-MM-dd').format(giftCard.expiresAt!),
                      ),
                    if (giftCard.isUsed && giftCard.usedAt != null)
                      _buildInfoRow(
                        'Used on',
                        DateFormat('yyyy-MM-dd HH:mm').format(giftCard.usedAt!),
                      ),
                    if (giftCard.notes != null && giftCard.notes!.isNotEmpty)
                      _buildInfoRow('Notes', giftCard.notes!),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!giftCard.isUsed)
                          CustomButton(
                            text: 'Copy Code',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: giftCard.code),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code copied to clipboard'),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            },
                            icon: Icons.copy,
                            type: ButtonType.secondary,
                          ),
                        const SizedBox(width: 8),
                        if (!giftCard.isUsed)
                          CustomButton(
                            text: 'Test Use',
                            onPressed: () => _testUseGiftCard(giftCard.code),
                            icon: Icons.check,
                            type: ButtonType.primary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textLightColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textColor),
            ),
          ),
        ],
      ),
    );
  }
}
