import 'package:flutter/material.dart';
import 'package:one_one/core/shared/spacing.dart';
import 'package:one_one/screens/setup/setup_step_page.dart';

class DobSetup extends StatefulWidget {
  final Function() onBack;
  final Function(DateTime) onSubmit;

  const DobSetup({
    super.key,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  State<DobSetup> createState() => DobSetupState();
}

class DobSetupState extends State<DobSetup> {
  DateTime? _selectedDate;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return SetupStepPage(
      title: "When's your birthday?",
      step: 2,
      totalSteps: 3,
      onBack: widget.onBack,
      child: GestureDetector(
        onTap: _selectDate,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: Spacing.s5, vertical: Spacing.s4
          ),
          margin: EdgeInsets.all(Spacing.s4),
          decoration: BoxDecoration(
            color: ColorScheme.of(context).surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ColorScheme.of(context).primary,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: ColorScheme.of(context).onSurface,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedDate != null
                      ? _formatDate(_selectedDate!)
                      : 'Select your date of birth',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedDate != null
                        ? ColorScheme.of(context).onSurface
                        : ColorScheme.of(context).onSurface.withAlpha(100),
                    fontWeight: _selectedDate != null
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: ColorScheme.of(context).onSurface,
              ),
            ],
          ),
        ),
      ),
      onNext: () {
        if (_selectedDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Please pick a valid date"
              )
            )
          );
        } else {
          widget.onSubmit(_selectedDate!);
        }
      },
    );
  }
}