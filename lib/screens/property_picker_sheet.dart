import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../services/supabase_repository.dart';
import '../widgets/app_common.dart';

/// A full-screen searchable picker for society / block / flat.
///
/// Replaces the inline autocomplete dropdowns, which grew and shrank the page
/// under the user's thumb and pushed downstream fields off-screen. A sheet
/// gives the phone keyboard its own space and cannot shift the page behind it.
class PropertyPickerSheet extends StatefulWidget {
  final String title;
  final String searchHint;
  final IconData icon;

  /// Called with the current query. Returns the options to show.
  final Future<List<PropertyOption>> Function(String query) loadOptions;

  const PropertyPickerSheet({
    Key? key,
    required this.title,
    required this.searchHint,
    required this.icon,
    required this.loadOptions,
  }) : super(key: key);

  /// Opens the picker and resolves to the chosen option, or null if dismissed.
  static Future<PropertyOption?> show(
    BuildContext context, {
    required String title,
    required String searchHint,
    required IconData icon,
    required Future<List<PropertyOption>> Function(String query) loadOptions,
  }) {
    return showModalBottomSheet<PropertyOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (context) => PropertyPickerSheet(
        title: title,
        searchHint: searchHint,
        icon: icon,
        loadOptions: loadOptions,
      ),
    );
  }

  @override
  State<PropertyPickerSheet> createState() => _PropertyPickerSheetState();
}

class _PropertyPickerSheetState extends State<PropertyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<PropertyOption> _options = const [];
  bool _isLoading = true;
  Timer? _debounce;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
    final token = ++_loadToken;
    setState(() => _isLoading = true);
    try {
      final options = await widget.loadOptions(query);
      if (!mounted || token != _loadToken) return;
      setState(() {
        _options = options;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _options = const [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load options: $error')),
      );
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 280),
      () => _load(query),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: AppColors.coral),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppStyles.headlineMd.copyWith(
                        color: AppColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: _load,
                decoration: AppStyles.buildInputDecoration(
                  hint: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            _load('');
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_options.isEmpty) {
      return AppEmptyState(
        icon: Icons.search_off,
        title: 'Nothing found',
        message: _searchController.text.trim().isEmpty
            ? 'No options are available yet.'
            : 'No match for "${_searchController.text.trim()}". '
                'Try a shorter search.',
      );
    }
    return Scrollbar(
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        itemCount: _options.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: AppColors.neutral100,
        ),
        itemBuilder: (context, index) {
          final option = _options[index];
          return ListTile(
            minVerticalPadding: AppSpacing.md,
            title: Text(
              option.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.bodyMd.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: option.propertyCode == null
                ? null
                : Text(
                    option.propertyCode!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodySm.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.neutral400,
            ),
            onTap: () => Navigator.pop(context, option),
          );
        },
      ),
    );
  }
}

/// The tappable row that opens a [PropertyPickerSheet]. Shows the current
/// selection, or a disabled state explaining what must be chosen first.
class PropertyPickerField extends StatelessWidget {
  final String label;
  final String placeholder;
  final IconData icon;
  final PropertyOption? value;
  final bool enabled;
  final String? disabledHint;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const PropertyPickerField({
    Key? key,
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.value,
    required this.enabled,
    required this.onTap,
    this.disabledHint,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selected = value;
    final showText = selected?.name ??
        (enabled ? placeholder : (disabledHint ?? placeholder));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.labelMd.copyWith(color: AppColors.navy),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          button: true,
          enabled: enabled,
          label: '$label: ${selected?.name ?? 'not selected'}',
          child: Material(
            color: enabled ? Colors.white : AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.minTapTarget + 8,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: selected != null
                        ? AppColors.coral
                        : AppColors.neutral200,
                    width: selected != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: enabled
                          ? (selected != null
                              ? AppColors.coral
                              : AppColors.neutral500)
                          : AppColors.neutral400,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            showText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.bodyMd.copyWith(
                              color: selected != null
                                  ? AppColors.navy
                                  : AppColors.neutral500,
                              fontWeight: selected != null
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          if (selected?.propertyCode != null)
                            Text(
                              selected!.propertyCode!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.labelSm.copyWith(
                                color: AppColors.neutral600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (selected != null && onClear != null)
                      IconButton(
                        tooltip: 'Clear $label',
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: onClear,
                      )
                    else if (enabled)
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.neutral400,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
