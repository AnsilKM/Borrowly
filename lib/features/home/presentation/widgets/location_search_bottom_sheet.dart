import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/location/location_provider.dart';
import 'package:borrowly/core/storage/local_storage_service.dart';
import 'package:borrowly/core/widgets/borrowly_button.dart';
import 'package:borrowly/core/widgets/borrowly_toast.dart';

/// Helper model for live geocoded location suggestions as the user types.
class LocationSuggestion {
  final String name;
  final String subTitle;
  final double lat;
  final double lng;

  const LocationSuggestion({
    required this.name,
    required this.subTitle,
    required this.lat,
    required this.lng,
  });
}

/// Bottom sheet that lets users set their active search location:
/// - "Use My Current Location" (GPS)
/// - Real-time live suggestions as user types
/// - Recent search history with individual delete & "Clear All"
class LocationSearchBottomSheet extends ConsumerStatefulWidget {
  const LocationSearchBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationSearchBottomSheet(),
    );
  }

  @override
  ConsumerState<LocationSearchBottomSheet> createState() =>
      _LocationSearchBottomSheetState();
}

class _LocationSearchBottomSheetState
    extends ConsumerState<LocationSearchBottomSheet> {
  late final TextEditingController _searchCtrl;
  late final ScrollController _scrollController;
  Timer? _debounceTimer;

  bool _isGettingGps = false;
  bool _isSearchingSuggestions = false;
  bool _isGeocodingDirect = false;
  String? _geocodeError;

  List<LocationSuggestion> _suggestions = [];
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _scrollController = ScrollController();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    final storage = ref.read(localStorageServiceProvider);
    setState(() {
      _recentSearches = storage.getRecentLocalitySearches();
    });
  }

  Future<void> _saveRecentSearch(String name) async {
    final storage = ref.read(localStorageServiceProvider);
    final list = List<String>.from(_recentSearches);
    list.remove(name);
    list.insert(0, name);
    if (list.length > 5) list.removeLast(); // Keep max 5 recent

    await storage.saveRecentLocalitySearches(list);
    if (mounted) {
      setState(() => _recentSearches = list);
    }
  }

  Future<void> _deleteRecentSearch(String name) async {
    final storage = ref.read(localStorageServiceProvider);
    final list = List<String>.from(_recentSearches)..remove(name);
    await storage.saveRecentLocalitySearches(list);
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() => _recentSearches = list);
    }
  }

  Future<void> _clearAllRecentSearches() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.saveRecentLocalitySearches([]);
    HapticFeedback.mediumImpact();
    if (mounted) {
      setState(() => _recentSearches = []);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isGettingGps = true;
      _geocodeError = null;
    });
    HapticFeedback.mediumImpact();

    await ref.read(activeLocationProvider.notifier).refreshGps();
    final locationState = ref.read(activeLocationProvider).valueOrNull;

    if (mounted) {
      setState(() => _isGettingGps = false);
      if (locationState?.hasLocation == true) {
        BorrowlyToast.show(
          context,
          'Location set to ${locationState!.fix!.localityName}',
          icon: Icons.location_on_rounded,
        );
        Navigator.of(context).pop();
      } else {
        BorrowlyToast.show(
          context,
          'Location permission denied. Please enable in Settings.',
          icon: Icons.location_off_rounded,
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.length < 2) {
      setState(() {
        _suggestions = [];
        _isSearchingSuggestions = false;
        _geocodeError = null;
      });
      return;
    }

    setState(() => _isSearchingSuggestions = true);

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final locations = await locationFromAddress(trimmed);
        final List<LocationSuggestion> results = [];

        for (final loc in locations.take(4)) {
          final placemarks =
              await placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final mainName = (p.subLocality != null && p.subLocality!.isNotEmpty)
                ? p.subLocality!
                : (p.locality != null && p.locality!.isNotEmpty)
                    ? p.locality!
                    : p.name ?? trimmed;

            final areaParts = [
              if (p.locality != null &&
                  p.locality!.isNotEmpty &&
                  p.locality != mainName)
                p.locality!,
              if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
                p.administrativeArea!,
            ];

            results.add(LocationSuggestion(
              name: mainName,
              subTitle: areaParts.isNotEmpty ? areaParts.join(', ') : 'Area',
              lat: loc.latitude,
              lng: loc.longitude,
            ));
          }
        }

        if (mounted) {
          setState(() {
            _suggestions = results;
            _isSearchingSuggestions = false;
            _geocodeError = results.isEmpty
                ? 'No matching areas found. Try a city or locality name.'
                : null;
          });
          if (results.isNotEmpty) {
            _scrollToBottom();
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _isSearchingSuggestions = false;
            _geocodeError = 'No matching area found. Try city or area name.';
          });
        }
      }
    });
  }

  Future<void> _selectSuggestion(LocationSuggestion suggestion) async {
    HapticFeedback.selectionClick();
    await ref.read(activeLocationProvider.notifier).setManualLocation(
          lat: suggestion.lat,
          lng: suggestion.lng,
          localityName: suggestion.name,
        );
    await _saveRecentSearch(suggestion.name);

    if (mounted) {
      BorrowlyToast.show(
        context,
        'Browsing items near ${suggestion.name}',
        icon: Icons.place_rounded,
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _geocodeDirectQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isGeocodingDirect = true;
      _geocodeError = null;
    });

    try {
      final locations = await locationFromAddress(trimmed);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        await ref.read(activeLocationProvider.notifier).setManualLocation(
              lat: loc.latitude,
              lng: loc.longitude,
              localityName: trimmed,
            );
        await _saveRecentSearch(trimmed);

        if (mounted) {
          BorrowlyToast.show(
            context,
            'Browsing items near $trimmed',
            icon: Icons.place_rounded,
          );
          Navigator.of(context).pop();
        }
      } else {
        setState(() =>
            _geocodeError = 'Could not find "$trimmed". Try a city name or area.');
      }
    } catch (e) {
      setState(() =>
          _geocodeError = 'Could not find "$trimmed". Try city or area name.');
    } finally {
      if (mounted) setState(() => _isGeocodingDirect = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxScreenHeight = MediaQuery.of(context).size.height;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxScreenHeight * 0.82,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg + (bottomInset > 0 ? 0 : 80.0),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      borderRadius: AppRadii.borderPill,
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.place_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Set Your Location',
                      style: AppTypography.headingSmall(isDark)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Use GPS Button
                BorrowlyButton(
                  label: 'Use My Current Location',
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  variant: BorrowlyButtonVariant.primary,
                  isFullWidth: true,
                  isLoading: _isGettingGps,
                  onPressed: _isGettingGps ? null : _useCurrentLocation,
                ),

                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm),
                      child: Text('or search manually',
                          style: AppTypography.bodySmall(isDark)),
                    ),
                    Expanded(
                        child: Divider(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Locality Search Input Field
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _searchCtrl,
                        textCapitalization: TextCapitalization.words,
                        style: AppTypography.bodyLarge(isDark),
                        onChanged: _onSearchChanged,
                        onFieldSubmitted: _geocodeDirectQuery,
                        decoration: InputDecoration(
                          hintText: 'Area name e.g. Kakkanad, Edappally...',
                          prefixIcon: _isSearchingSuggestions
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : const Icon(Icons.search_rounded,
                                  color: AppColors.primary, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkSurfaceSubtle
                              : AppColors.surfaceWarm,
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.borderPill,
                            borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.borderSubtle),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          errorText: _geocodeError,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      height: 48,
                      child: BorrowlyButton(
                        label: 'Go',
                        size: BorrowlyButtonSize.small,
                        isLoading: _isGeocodingDirect,
                        onPressed: _isGeocodingDirect
                            ? null
                            : () => _geocodeDirectQuery(_searchCtrl.text),
                      ),
                    ),
                  ],
                ),

                // Live Suggestions List (Shown as user types)
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Suggestions',
                    style: AppTypography.labelText(isDark)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceSubtle
                          : AppColors.surfaceWarm,
                      borderRadius: AppRadii.borderLg,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Column(
                      children: _suggestions.map((sug) {
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                color: AppColors.primary, size: 16),
                          ),
                          title: Text(
                            sug.name,
                            style: AppTypography.bodyMedium(isDark)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            sug.subTitle,
                            style: AppTypography.bodySmall(isDark),
                          ),
                          onTap: () => _selectSuggestion(sug),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // Recent Searches (With delete action & Clear All)
                if (_recentSearches.isNotEmpty && _suggestions.isEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Searches',
                        style: AppTypography.labelText(isDark)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _clearAllRecentSearches,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Clear All',
                          style: AppTypography.bodySmall(isDark).copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: _recentSearches.map((name) {
                      return InputChip(
                        avatar: const Icon(Icons.history_rounded,
                            size: 14, color: AppColors.primary),
                        label:
                            Text(name, style: AppTypography.bodySmall(isDark)),
                        onPressed: () => _geocodeDirectQuery(name),
                        onDeleted: () => _deleteRecentSearch(name),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14),
                        deleteIconColor: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceSubtle
                            : AppColors.surfaceWarm,
                        shape: const StadiumBorder(),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
