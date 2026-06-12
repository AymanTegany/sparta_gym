
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sparta_gym/features/auth/presentation/cubit/auth_state.dart';
import 'package:sparta_gym/features/auth/presentation/cubit/auth_cubit.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _licenseKeyCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _licenseKeyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().register(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      licenseKey: _licenseKeyCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthRegistered) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم إنشاء الحساب "${state.username}" بنجاح!'),
                backgroundColor: theme.colorScheme.secondary,
              ),
            );
            Navigator.pop(context);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Container(
                width: 500,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    _buildHeader(primary),
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(
                              _usernameCtrl,
                              'اسم المستخدم',
                              Icons.person_outline,
                            ),
                            _buildTextField(
                              _passwordCtrl,
                              'كلمة المرور',
                              Icons.lock_outline,
                              isPass: true,
                              obscure: _obscurePass,
                              onToggle: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                            _buildTextField(
                              _confirmCtrl,
                              'تأكيد كلمة المرور',
                              Icons.lock_reset,
                              isPass: true,
                              obscure: _obscureConfirm,
                              onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              validator: (v) => v != _passwordCtrl.text
                                  ? 'غير متطابقة'
                                  : null,
                            ),
                            const Divider(),
                            _buildTextField(
                              _licenseKeyCtrl,
                              'كرت الاشتراك (License Card)',
                              Icons.vignette_outlined,
                              hint: 'أدخل الكرت الذي حصلت عليه من المبرمج',
                            ),
                            const SizedBox(height: 30),

                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                final loading = state is AuthLoading;
                                return SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: loading ? null : _submit,
                                    child: loading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : const Text('إنشاء الحساب'),
                                  ),
                                );
                              },
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('العودة للدخول'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_add, color: Colors.white, size: 40),
          SizedBox(height: 10),
          Text(
            'إنشاء حساب مستخدم',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isPass = false,
    bool? obscure,
    String? hint,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure ?? false,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: isPass
              ? IconButton(
                  icon: Icon(
                    obscure! ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
        validator:
            validator ?? (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
      ),
    );
  }
}
