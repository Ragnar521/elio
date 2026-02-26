import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/elio_colors.dart';

class DebouncedSearchBar extends StatefulWidget {
  const DebouncedSearchBar({
    super.key,
    required this.onSearch,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  final Function(String) onSearch;
  final Duration debounceDuration;

  @override
  State<DebouncedSearchBar> createState() => DebouncedSearchBarState();
}

class DebouncedSearchBarState extends State<DebouncedSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();

    // Start new debounce timer
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onSearch(_controller.text);
    });

    // Trigger rebuild to show/hide clear button
    setState(() {});
  }

  void clear() {
    _controller.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: const TextStyle(color: ElioColors.darkPrimaryText),
      cursorColor: ElioColors.darkAccent,
      decoration: InputDecoration(
        filled: true,
        fillColor: ElioColors.darkSurface,
        hintText: 'Search entries...',
        hintStyle: TextStyle(
          color: ElioColors.darkPrimaryText.withOpacity(0.4),
        ),
        prefixIcon: Icon(
          Icons.search,
          color: ElioColors.darkPrimaryText.withOpacity(0.5),
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: ElioColors.darkPrimaryText.withOpacity(0.5),
                ),
                onPressed: clear,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: ElioColors.darkSurface,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: ElioColors.darkAccent,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
