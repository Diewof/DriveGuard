import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_typography.dart';
import '../../../core/utils/app_spacing.dart';
import '../../../domain/entities/emergency_contact.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // Paso 1: Datos de cuenta
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Paso 2: Datos personales
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();

  // Paso 3: Contactos de emergencia
  final List<EmergencyContact> _emergencyContacts = [];

  bool _acceptTerms = false;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _register();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _register() {
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes agregar al menos un contacto de emergencia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            age: int.tryParse(_ageController.text) ?? 0,
            emergencyContacts: _emergencyContacts,
          ),
        );
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Contacto de Emergencia'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                    prefixText: '+57 ',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el teléfono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relación (Ej: Madre, Padre, Hermano)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa la relación';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _emergencyContacts.add(
                    EmergencyContact(
                      name: nameController.text.trim(),
                      phoneNumber: '+57${phoneController.text.trim()}',
                      relationship: relationshipController.text.trim(),
                      priority: _emergencyContacts.length + 1,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_outlined, color: AppColors.textPrimary),
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Paso ${_currentStep + 1} de 3',
          style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                margin: EdgeInsets.all(AppSpacing.md),
              ),
            );
          }
          if (state.isAuthenticated) {
            context.go('/dashboard');
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // Indicador de progreso
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: List.generate(
                    3,
                    (index) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: index < 2 ? AppSpacing.sm : 0,
                        ),
                        height: AppSpacing.xs,
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(AppSpacing.borderMedium),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Contenido
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildAccountStep(),
                      _buildPersonalInfoStep(),
                      _buildEmergencyContactsStep(),
                    ],
                  ),
                ),
              ),

              // Botones de navegación
              Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return AuthButton(
                      text: _currentStep < 2 ? 'Continuar' : 'Crear Cuenta',
                      onPressed: _nextStep,
                      isLoading: state.isLoading,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos de Cuenta',
            style: AppTypography.h2,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Crea tu cuenta con email y contraseña',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.xl),
          AuthTextField(
            label: 'Email',
            hint: 'ejemplo@correo.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          const SizedBox(height: 24),
          AuthTextField(
            label: 'Contraseña',
            hint: 'Mínimo 6 caracteres',
            controller: _passwordController,
            isPassword: true,
            validator: Validators.password,
            prefixIcon: const Icon(Icons.lock_outlined),
          ),
          const SizedBox(height: 24),
          AuthTextField(
            label: 'Confirmar Contraseña',
            hint: 'Confirma tu contraseña',
            controller: _confirmPasswordController,
            isPassword: true,
            validator: (value) => Validators.confirmPassword(
              value,
              _passwordController.text,
            ),
            prefixIcon: const Icon(Icons.lock_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Personal',
            style: AppTypography.h2,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Completa tus datos personales',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.xl),
          AuthTextField(
            label: 'Nombre Completo',
            hint: 'Juan Pérez',
            controller: _nameController,
            validator: Validators.name,
            prefixIcon: const Icon(Icons.person_outlined),
          ),
          const SizedBox(height: 24),
          AuthTextField(
            label: 'Teléfono',
            hint: '3001234567',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu teléfono';
              }
              return null;
            },
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          const SizedBox(height: 24),
          AuthTextField(
            label: 'Dirección',
            hint: 'Calle 123 #45-67',
            controller: _addressController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu dirección';
              }
              return null;
            },
            prefixIcon: const Icon(Icons.home_outlined),
          ),
          const SizedBox(height: 24),
          AuthTextField(
            label: 'Edad',
            hint: '18',
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu edad';
              }
              final age = int.tryParse(value);
              if (age == null || age < 18) {
                return 'Debes ser mayor de 18 años';
              }
              return null;
            },
            prefixIcon: const Icon(Icons.cake_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contactos de Emergencia',
            style: AppTypography.h2,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Agrega al menos un contacto de emergencia',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.xl),

          // Lista de contactos
          if (_emergencyContacts.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.contacts_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay contactos agregados',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _emergencyContacts.length,
              itemBuilder: (context, index) {
                final contact = _emergencyContacts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[900],
                      child: Text(
                        contact.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      contact.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${contact.phoneNumber}\n${contact.relationship}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _emergencyContacts.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Botón agregar contacto
          OutlinedButton.icon(
            onPressed: _showAddContactDialog,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Contacto'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: Colors.blue[900]!),
              foregroundColor: Colors.blue[900],
            ),
          ),

          const SizedBox(height: 32),

          // Términos y condiciones
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
                  });
                },
                activeColor: Colors.blue[900],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                        children: [
                          const TextSpan(text: 'Acepto los '),
                          TextSpan(
                            text: 'Términos y Condiciones',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' y la '),
                          TextSpan(
                            text: 'Política de Privacidad',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Link a login
          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
                children: [
                  const TextSpan(text: '¿Ya tienes cuenta? '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Inicia Sesión',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}