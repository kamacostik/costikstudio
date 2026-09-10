import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: 'user@costik.com');
  final _passwordController = TextEditingController(text: '123456');
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authCubit = context.read<AuthCubit>();
    final success = await authCubit.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      if (authCubit.state.isAdmin) {
        context.go(AppRoutes.adminBilling);
      } else {
        context.go(AppRoutes.billing);
      }
    } else {
      setState(() {
        _errorMessage =
            authCubit.state.errorMessage ?? 'Email atau password salah.';
      });
    }
  }

  void _fillPreset(String email) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = '123456';
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return SingleChildScrollView(
          child: ResponsiveSection(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 80),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: CostikStudioTheme.navy.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: CostikStudioTheme.navy,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Masuk ke CostikStudio',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Gunakan akun Supabase atau dummy saat env belum aktif',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: CostikStudioTheme.slate,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_clock_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: FilledButton(
                            onPressed: authState.isLoading
                                ? null
                                : _handleLogin,
                            child: authState.isLoading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Masuk'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          'Quick Presets Dummy:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: CostikStudioTheme.slate,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => _fillPreset('user@costik.com'),
                              child: const Text(
                                'Fill Customer (user@costik.com)',
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => _fillPreset('admin@costik.com'),
                              child: const Text(
                                'Fill Admin (admin@costik.com)',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
