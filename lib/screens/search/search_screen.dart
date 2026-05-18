import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../providers/restaurant_provider.dart';
import '../../core/constants/route_names.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      context.read<RestaurantProvider>().clearSearch();
      setState(() => _searching = false);
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      await context.read<RestaurantProvider>().search(query.trim());
      if (mounted) setState(() => _searching = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();
    final results = provider.searchResults;
    final query = _controller.text.trim();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onQueryChanged,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: 'Search restaurants, cuisines…',
            hintStyle: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.warmGrey.withOpacity(0.6)),
            border: InputBorder.none,
          ),
        ),
      ),
      body: _searching
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta))
          : query.isEmpty
              ? Center(
                  child: Text('Start typing to search',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.warmGrey)))
              : results.isEmpty
                  ? Center(
                      child: Text('No results for "$query"',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.warmGrey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final r = results[i];
                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, RouteNames.kRestaurantDetail,
                              arguments: r),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.lightGrey
                                      .withOpacity(0.6)),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: r.mediaUrls.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: r.mediaUrls.first,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                              color: r.tileColor),
                                          errorWidget: (_, __, ___) =>
                                              Container(color: r.tileColor),
                                        )
                                      : StripeTile(
                                          color: r.tileColor,
                                          width: 80,
                                          height: 80,
                                          borderRadius: BorderRadius.zero,
                                        ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(r.name,
                                            style: GoogleFonts.fraunces(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text(
                                            '${r.category} · ${r.neighborhood}',
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.warmGrey)),
                                        const SizedBox(height: 4),
                                        StarRating(
                                            rating: r.avgRating, size: 11),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
