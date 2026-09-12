import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:flutter/material.dart';

class SignageTableTab extends StatelessWidget {
  const SignageTableTab({
    super.key,
    required this.label,
    required this.icon,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? CostikStudioTheme.primary
                    : CostikStudioTheme.slate,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? CostikStudioTheme.navy
                      : CostikStudioTheme.slate,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      (isSelected
                              ? CostikStudioTheme.primary
                              : CostikStudioTheme.slate)
                          .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? CostikStudioTheme.primary
                        : CostikStudioTheme.slate,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignageTableTabBar extends StatelessWidget {
  const SignageTableTabBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class SignageEmptyTableState extends StatelessWidget {
  const SignageEmptyTableState({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: CostikStudioTheme.slate.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(color: CostikStudioTheme.slate),
            ),
          ],
        ),
      ),
    );
  }
}

class SignageDataTable extends StatefulWidget {
  const SignageDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.emptyIcon,
    required this.emptyMessage,
    this.rowsPerPage = 10,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final IconData emptyIcon;
  final String emptyMessage;
  final int rowsPerPage;

  @override
  State<SignageDataTable> createState() => _SignageDataTableState();
}

class _SignageDataTableState extends State<SignageDataTable> {
  int _pageIndex = 0;

  @override
  void didUpdateWidget(covariant SignageDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rows.length != oldWidget.rows.length) {
      _pageIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return SignageEmptyTableState(
        icon: widget.emptyIcon,
        message: widget.emptyMessage,
      );
    }

    final totalPages = (widget.rows.length / widget.rowsPerPage).ceil();
    final safePageIndex = _pageIndex.clamp(0, totalPages - 1);
    final start = safePageIndex * widget.rowsPerPage;
    final end = (start + widget.rowsPerPage).clamp(0, widget.rows.length);
    final visibleRows = widget.rows.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: const WidgetStatePropertyAll(
                    Color(0xFFF8FAFC),
                  ),
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  columns: widget.columns,
                  rows: visibleRows,
                ),
              ),
            );
          },
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 12),
          _TablePaginationBar(
            currentPage: safePageIndex + 1,
            totalPages: totalPages,
            totalItems: widget.rows.length,
            onPrevious: safePageIndex == 0
                ? null
                : () => setState(() => _pageIndex = safePageIndex - 1),
            onNext: safePageIndex >= totalPages - 1
                ? null
                : () => setState(() => _pageIndex = safePageIndex + 1),
          ),
        ],
      ],
    );
  }
}

class _TablePaginationBar extends StatelessWidget {
  const _TablePaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$totalItems data • Halaman $currentPage/$totalPages',
          style: const TextStyle(
            color: CostikStudioTheme.slate,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(onPressed: onPrevious, child: const Text('Sebelumnya')),
        const SizedBox(width: 8),
        FilledButton.tonal(onPressed: onNext, child: const Text('Berikutnya')),
      ],
    );
  }
}

class SignageReferenceCell extends StatelessWidget {
  const SignageReferenceCell({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.reference,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String reference;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CostikStudioTheme.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                reference,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CostikStudioTheme.slate,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SignageStatusBadge extends StatelessWidget {
  const SignageStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

DataColumn signageDataColumn(String label) {
  return DataColumn(
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}
