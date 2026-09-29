import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

/// Bouton rond flottant « site » — déplaçable (position mémorisée).
class ChefSiteFab extends StatefulWidget {
  final String location;

  const ChefSiteFab({super.key, required this.location});

  static bool shouldShow(String path) {
    if (!path.startsWith('/chef')) return false;
    if (path.startsWith('/chef/pointage')) return false;
    if (path.startsWith('/chef/select-site')) return false;
    return true;
  }

  @override
  State<ChefSiteFab> createState() => _ChefSiteFabState();
}

class _ChefSiteFabState extends State<ChefSiteFab> {
  Offset? _offset; // null = coin bas-droit par défaut
  static const _kX = 'chef_fab_x';
  static const _kY = 'chef_fab_y';
  static const _size = 56.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final x = p.getDouble(_kX);
    final y = p.getDouble(_kY);
    if (x != null && y != null && mounted) {
      setState(() => _offset = Offset(x, y));
    }
  }

  Future<void> _save(Offset o) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kX, o.dx);
    await p.setDouble(_kY, o.dy);
  }

  @override
  Widget build(BuildContext context) {
    if (!ChefSiteFab.shouldShow(widget.location)) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final bottomNav = 72.0;

    // Position par défaut : bas-droite au-dessus de la nav
    final defaultPos = Offset(
      size.width - _size - 16,
      size.height - padding.bottom - bottomNav - _size - 16,
    );
    final pos = _offset ?? defaultPos;

    return Positioned(
      left: pos.dx.clamp(8.0, size.width - _size - 8),
      top: pos.dy.clamp(padding.top + 8, size.height - padding.bottom - bottomNav - _size - 8),
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            final cur = _offset ?? defaultPos;
            _offset = Offset(
              (cur.dx + d.delta.dx).clamp(8.0, size.width - _size - 8),
              (cur.dy + d.delta.dy).clamp(
                padding.top + 8,
                size.height - padding.bottom - bottomNav - _size - 8,
              ),
            );
          });
        },
        onPanEnd: (_) {
          if (_offset != null) _save(_offset!);
        },
        onTap: () => context.push('/chef/select-site'),
        child: Material(
          elevation: 6,
          shape: const CircleBorder(),
          color: AppColors.secondary,
          child: SizedBox(
            width: _size,
            height: _size,
            child: const Icon(
              Icons.apartment_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
