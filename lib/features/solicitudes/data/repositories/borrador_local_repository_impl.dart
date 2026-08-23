import '../../domain/entities/datos_solicitud.dart';
import '../../domain/repositories/borrador_local_repository.dart';
import '../datasources/borrador_local_datasource.dart';

class BorradorLocalRepositoryImpl implements BorradorLocalRepository {
  const BorradorLocalRepositoryImpl(this._datasource);

  final BorradorLocalDatasource _datasource;

  @override
  Future<void> guardar(DatosSolicitud datos) {
    return _datasource.guardar(datos.toJson());
  }

  @override
  Future<DatosSolicitud?> leer() async {
    final json = _datasource.leer();
    if (json == null) return null;
    return DatosSolicitud.fromJson(json);
  }

  @override
  Future<void> limpiar() {
    return _datasource.limpiar();
  }
}
