import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../data/employees_repository.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  DateTime? _joiningDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfaceBg,
      appBar: AppBar(
        title: const Text('Add New Employee'),
        backgroundColor: colors.cardBg,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('Personal Info'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Full Name', _nameCtrl, Icons.person_outline)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Employee Code', _codeCtrl, Icons.badge_outlined)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Email Address', _emailCtrl, Icons.email_outlined)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Phone Number', _phoneCtrl, Icons.phone_outlined)),
                ],
              ),
              const SizedBox(height: 32),
              _sectionHeader('Professional Details'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Designation', _designationCtrl, Icons.work_outline)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDatePicker('Joining Date', _joiningDate, (d) => setState(() => _joiningDate = d)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('Basic Salary', _salaryCtrl, Icons.payments_outlined, isNumeric: true),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submit,
                  child: const Text('Register Employee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(color: context.appColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool isNumeric = false}) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: colors.textTertiary),
            filled: true,
            fillColor: colors.cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
          ),
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? value, Function(DateTime) onSelect) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (d != null) onSelect(d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 20, color: colors.textTertiary),
                const SizedBox(width: 8),
                Text(
                  value == null ? 'Select Date' : '${value.year}-${value.month}-${value.day}',
                  style: TextStyle(color: value == null ? colors.textTertiary : colors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _joiningDate == null) {
       if (_joiningDate == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select joining date')));
       return;
    }

    final emp = Employee(
      id: '', // Backend gen
      tenantId: '', // Backend gen
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
      employeeCode: _codeCtrl.text,
      designation: _designationCtrl.text,
      joiningDate: _joiningDate?.toIso8601String(),
      basicSalary: double.tryParse(_salaryCtrl.text),
      status: 'active',
      createdAt: '',
    );

    try {
      await ref.read(employeesRepositoryProvider).create(emp);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee added successfully')));
        Navigator.pop(context);
        ref.invalidate(employeesListProvider);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
