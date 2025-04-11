import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SaveRushPage extends StatefulWidget {
  final String contractNo;
  final String hpprice;

  const SaveRushPage({
    Key? key,
    required this.contractNo,
    required this.hpprice,
  }) : super(key: key);

  @override
  _SaveRushPageState createState() => _SaveRushPageState();
}

class _SaveRushPageState extends State<SaveRushPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _followFeeController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  int _selectedIndex = 0;

  @override
  void dispose() {
    _noteController.dispose();
    _dueDateController.dispose();
    _amountController.dispose();
    _followFeeController.dispose();
    _mileageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      "บันทึกสำเร็จ",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    _buildInfoRow("📋 ข้อความ", _noteController.text),
                    _buildInfoRow("🗓 วันนัดชำระ", _dueDateController.text),
                    _buildInfoRow("💰 จำนวนเงิน", _amountController.text),
                    _buildInfoRow("🧾 ค่าติดตาม", _followFeeController.text),
                    _buildInfoRow("🚗 ระยะไมล์", _mileageController.text),
                    _buildInfoRow("📍 สถานที่", _locationController.text),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      icon: Icon(Icons.check),
                      label: Text("ตกลง", style: TextStyle(fontSize: 16)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
      );
    }
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        _submitForm();
        break;
      case 1:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📷 เปิดกล้อง (ยังไม่เชื่อมต่อ)')),
        );
        break;
      case 2:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ℹ️ เมนูอื่น ๆ')));
        break;
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.prompt(),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.amber.shade800),
          labelText: label,
          labelStyle: GoogleFonts.prompt(color: Colors.grey.shade800),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.amber.shade800, width: 1.5),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'กรุณากรอก $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Colors.amber.shade700;
    final grey = Colors.grey.shade900;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('📋 ระบบจัดเก็บเร่งรัด', style: GoogleFonts.prompt()),
        backgroundColor: yellow,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                color: Colors.amber.shade50,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: Icon(Icons.receipt_long, color: grey),
                  title: Text(
                    'เลขสัญญา: ${widget.contractNo}',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'ยอดจัด: ${widget.hpprice} บาท',
                    style: GoogleFonts.prompt(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'ข้อความ',
                icon: Icons.notes,
                controller: _noteController,
                maxLines: 3,
              ),
              _buildTextField(
                label: 'วันนัดชำระ',
                icon: Icons.date_range,
                controller: _dueDateController,
                keyboardType: TextInputType.datetime,
              ),
              _buildTextField(
                label: 'จำนวนเงินนัดชำระ',
                icon: Icons.attach_money,
                controller: _amountController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                label: 'ค่าติดตาม',
                icon: Icons.money_off,
                controller: _followFeeController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                label: 'ระยะไมล์',
                icon: Icons.directions_car,
                controller: _mileageController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                label: 'สถานที่',
                icon: Icons.location_on,
                controller: _locationController,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.save), label: 'บันทึก'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'กล้อง'),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'อื่น ๆ',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber.shade800,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
