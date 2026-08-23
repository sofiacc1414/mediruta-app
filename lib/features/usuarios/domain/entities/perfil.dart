import 'perfil_domiciliario.dart';
import 'perfil_paciente.dart';

/// Perfil del usuario autenticado — datos comunes más los específicos de
/// cada rol que tenga la cuenta (un usuario puede tener [paciente] y
/// [domiciliario] a la vez, modelo multirrol — context.md Parte B 4.1).
class Perfil {
  const Perfil({
    required this.nombreCompleto,
    required this.telefono,
    required this.paciente,
    required this.domiciliario,
  });

  final String? nombreCompleto;
  final String? telefono;
  final PerfilPaciente? paciente;
  final PerfilDomiciliario? domiciliario;

  factory Perfil.fromJson(Map<String, dynamic> json) {
    final paciente = json['paciente'] as Map<String, dynamic>?;
    final domiciliario = json['domiciliario'] as Map<String, dynamic>?;
    return Perfil(
      nombreCompleto: json['nombreCompleto'] as String?,
      telefono: json['telefono'] as String?,
      paciente: paciente != null ? PerfilPaciente.fromJson(paciente) : null,
      domiciliario: domiciliario != null
          ? PerfilDomiciliario.fromJson(domiciliario)
          : null,
    );
  }
}
