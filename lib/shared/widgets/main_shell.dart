import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/transactions/presentation/quick_input_sheet.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickCatatSheet(context),
        tooltip: 'Catat Transaksi',
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppPalette.borderColor(context)),
          ),
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          color: AppPalette.surfaceColor(context),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Beranda',
                selected: navigationShell.currentIndex == 0,
                onTap: () => navigationShell.goBranch(0),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Mutasi',
                selected: navigationShell.currentIndex == 1,
                onTap: () => navigationShell.goBranch(1),
              ),
              const SizedBox(width: 48),
              _NavItem(
                icon: Icons.insights_outlined,
                activeIcon: Icons.insights_rounded,
                label: 'Insight',
                selected: navigationShell.currentIndex == 2,
                onTap: () => navigationShell.goBranch(2),
              ),
              _NavItem(
                icon: Icons.tune_outlined,
                activeIcon: Icons.tune_rounded,
                label: 'Setelan',
                selected: navigationShell.currentIndex == 3,
                onTap: () => navigationShell.goBranch(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickCatatSheet(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryText = AppPalette.secondaryTextColor(context);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catat Transaksi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _SheetActionTile(
                icon: Icons.bolt_rounded,
                title: 'Input Cepat 1 Kalimat',
                subtitle: 'Contoh: "parkir 5rb cash, kopi 25rb qris"',
                accent: AppPalette.accent(context),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const QuickInputSheet(),
                  );
                },
              ),
              const SizedBox(height: 10),
              _SheetActionTile(
                icon: Icons.edit_note_rounded,
                title: 'Catat Manual',
                subtitle: 'Isi jumlah, kategori, dan metode bayar secara lengkap',
                accent: AppPalette.incomeColor(context),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/transactions/add');
                },
              ),
              const SizedBox(height: 10),
              _SheetActionTile(
                icon: Icons.document_scanner_outlined,
                title: 'Pindai Struk (OCR + AI)',
                subtitle: 'Foto struk belanja untuk ekstrak otomatis',
                accent: AppPalette.accent(context),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/scan');
                },
              ),
              _SheetActionTile(
                icon: Icons.schedule_rounded,
                title: 'Pendapatan Tertunda',
                subtitle: 'Catat penghasilan harian sebelum cair mingguan',
                accent: AppPalette.warningColor(context),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/pending-income');
                },
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Tip: Kamu juga bisa langsung ketuk Mutasi untuk mencari transaksi.',
                  style: TextStyle(fontSize: 11, color: secondaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppPalette.accent(context)
        : AppPalette.secondaryTextColor(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _SheetActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryText = AppPalette.secondaryTextColor(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.borderColor(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: secondaryText),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: secondaryText),
          ],
        ),
      ),
    );
  }
}
