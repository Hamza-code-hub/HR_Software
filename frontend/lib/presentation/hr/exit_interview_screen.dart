import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../data/hr_ops_repository.dart';
import '../../data/models/hr_ops.dart';

class ExitInterviewScreen extends ConsumerStatefulWidget {
  const ExitInterviewScreen({super.key, required this.resignationId});
  final String resignationId;

  @override
  ConsumerState<ExitInterviewScreen> createState() => _ExitInterviewScreenState();
}

class _ExitInterviewScreenState extends ConsumerState<ExitInterviewScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  ExitInterview? _interview;

  final _reasonCtrl = TextEditingController();
  final _mgmtCtrl = TextEditingController();
  final _cultureCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();
  bool _recommend = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(hrOpsRepositoryProvider).getExitInterview(widget.resignationId);
      if (data != null) {
        _interview = data;
        _reasonCtrl.text = data.reasonForLeaving;
        _mgmtCtrl.text = data.feedbackManagement;
        _cultureCtrl.text = data.feedbackCulture;
        _commentsCtrl.text = data.additionalComments;
        _recommend = data.recommendCompany;
      }
    } catch (e) {
      // Not found or error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfaceBg,
      appBar: AppBar(
        title: const Text('Exit Interview Feed'),
        backgroundColor: colors.cardBg,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Final Feedback'),
                    const SizedBox(height: 16),
                    _buildTextField('Main reason for leaving', _reasonCtrl),
                    const SizedBox(height: 16),
                    _buildTextField('Feedback on Management', _mgmtCtrl, maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTextField('Feedback on Company Culture', _cultureCtrl, maxLines: 3),
                    const SizedBox(height: 24),
                    _sectionTitle('Recommendation'),
                    SwitchListTile(
                      title: const Text('Would you recommend this company?'),
                      value: _recommend,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) => setState(() => _recommend = val),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Additional Comments', _commentsCtrl, maxLines: 4),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _save,
                        child: const Text('Submit Interview Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(color: context.appColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final interview = ExitInterview(
      resignationId: widget.resignationId,
      reasonForLeaving: _reasonCtrl.text,
      feedbackManagement: _mgmtCtrl.text,
      feedbackCulture: _cultureCtrl.text,
      recommendCompany: _recommend,
      additionalComments: _commentsCtrl.text,
    );

    try {
      await ref.read(hrOpsRepositoryProvider).saveExitInterview(interview);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exit interview saved successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
