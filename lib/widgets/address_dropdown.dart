import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/address_service.dart';

class AddressDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<AddressItem> items;
  final AddressItem? value;
  final bool loading;
  final ValueChanged<AddressItem?> onChanged;

  const AddressDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<AddressItem>(
      // the key makes the field reset when its list or value changes
      key: ValueKey('${items.length}-${value?.code}'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: loading ? '$label (loading...)' : label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e.name, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (loading || items.isEmpty) ? null : onChanged,
      validator: (v) => v == null ? 'Select your $label' : null,
    );
  }
}