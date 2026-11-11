import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class LauncherService {
  static Future<bool> openPhone(BuildContext context, String rawPhone, String passengerName) async {
    final cleanRaw = rawPhone.trim();
    if (cleanRaw.isEmpty) {
      _showNotice(context, 'Brak numeru telefonu dla tego pasażera.', Icons.warning);
      return false;
    }

    // Jeśli w arkuszu jest kilka numerów oddzielonych ukośnikiem "/"
    final parts = cleanRaw.split('/').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    if (parts.length > 1) {
      final selectedNumber = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wybierz numer: $passengerName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ...parts.map(
                  (phone) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.brandingOrange,
                      child: Icon(Icons.phone, color: Colors.white, size: 18),
                    ),
                    title: Text(
                      phone,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.gray),
                    onTap: () => Navigator.pop(ctx, phone),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selectedNumber != null) {
        if (!context.mounted) return false;
        return _dial(context, selectedNumber, passengerName);
      }
      return false;
    }

    return _dial(context, parts.first, passengerName);
  }

  static Future<bool> _dial(BuildContext context, String phoneNumber, String passengerName) async {
    final sanitized = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: sanitized);

    bool launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri);
      }
    } catch (_) {
      launched = false;
    }

    // Jeśli launchUrl się nie powiódł (np. na Symulatorze iOS lub tablecie bez GSM)
    if (!launched && context.mounted) {
      _showSimulatorCallFallback(context, phoneNumber, passengerName);
      return false;
    }

    return launched;
  }

  static void _showSimulatorCallFallback(
    BuildContext context,
    String phoneNumber,
    String passengerName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk, color: AppColors.brandingOrange),
            SizedBox(width: 8),
            Text('Połączenie', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pasażer: $passengerName', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            SelectableText(
              phoneNumber,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandingOrange,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.gray),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Symulator iOS nie posiada aplikacji telefonu. Na fizycznym telefonie dialer uruchomi się automatycznie.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.darkGray),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkGray,
              side: const BorderSide(color: AppColors.lightGray),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phoneNumber));
              Navigator.pop(ctx);
              _showNotice(context, 'Skopiowano numer $phoneNumber do schowka!', Icons.content_copy);
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Skopiuj numer'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  static Future<bool> openNavigation(BuildContext context, String address) async {
    final cleanAddress = address.trim();
    if (cleanAddress.isEmpty) {
      _showNotice(context, 'Brak adresu docelowego.', Icons.warning);
      return false;
    }

    final query = Uri.encodeComponent(cleanAddress);
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    try {
      final success = await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      if (!success && context.mounted) {
        _showNotice(context, 'Nie udało się otworzyć mapy.', Icons.error);
      }
      return success;
    } catch (e) {
      if (context.mounted) {
        _showNotice(context, 'Błąd uruchamiania mapy: $e', Icons.error);
      }
      return false;
    }
  }

  static Future<bool> openFullRoute(BuildContext context, String routeUrl) async {
    final uri = Uri.tryParse(routeUrl);
    if (uri == null) {
      _showNotice(context, 'Nieprawidłowy link do trasy.', Icons.warning);
      return false;
    }

    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success && context.mounted) {
        _showNotice(context, 'Nie udało się otworzyć trasy w mapach.', Icons.error);
      }
      return success;
    } catch (e) {
      if (context.mounted) {
        _showNotice(context, 'Błąd: $e', Icons.error);
      }
      return false;
    }
  }

  static void _showNotice(BuildContext context, String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Row(
          children: [
            Icon(icon, color: AppColors.brandingOrange, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
