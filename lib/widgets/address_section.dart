import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddressSection extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;

  const AddressSection({Key? key, this.initialValue, required this.onChanged})
    : super(key: key);

  @override
  State<AddressSection> createState() => _AddressSectionState();
}

class _AddressSectionState extends State<AddressSection> {
  final List<String> addressTypes = [
    'ที่อยู่ปัจจุบัน',
    'ที่อยู่ตามทะเบียนราษฎร์',
    'ที่ทำงาน',
    'ที่อยู่พ่อ/แม่',
    'ที่อยู่ใหม่จากการสืบทราบ',
    'อื่นๆ',
  ];

  String? _selectedAddressType;
  bool _isOtherAddress = false;
  final TextEditingController _otherAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedAddressType = widget.initialValue;
    _isOtherAddress = (_selectedAddressType == 'อื่นๆ');
    if (_isOtherAddress) {
      _otherAddressController.text = '';
    }
  }

  @override
  void dispose() {
    _otherAddressController.dispose();
    super.dispose();
  }

  void _handleAddressTypeChange(String? value) {
    setState(() {
      _selectedAddressType = value;
      if (value == 'อื่นๆ') {
        _isOtherAddress = true;
        _otherAddressController.text = '';
        widget.onChanged(''); // เคลียร์ค่า
      } else {
        _isOtherAddress = false;
        widget.onChanged(value ?? '');
      }
    });
  }

  void _handleOtherAddressChange(String val) {
    widget.onChanged(val);
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Colors.amber.shade700;
    final grey = Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _isOtherAddress ? 'อื่นๆ' : _selectedAddressType,
          items:
              addressTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
          onChanged: _handleAddressTypeChange,
          decoration: InputDecoration(
            labelText: 'ที่อยู่ติดตาม',
            labelStyle: GoogleFonts.prompt(color: yellow),
            prefixIcon: Icon(Icons.location_city, color: yellow),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: yellow, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณาเลือกที่อยู่ติดตาม';
            }
            return null;
          },
        ),
        if (_isOtherAddress) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _otherAddressController,
            decoration: InputDecoration(
              labelText: 'กรุณาระบุที่อยู่ติดตาม',
              prefixIcon: Icon(Icons.edit_location, color: yellow),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: yellow, width: 1.5),
              ),
            ),
            onChanged: _handleOtherAddressChange,
            validator: (value) {
              if (_isOtherAddress && (value == null || value.isEmpty)) {
                return 'กรุณาระบุที่อยู่ติดตาม';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}
