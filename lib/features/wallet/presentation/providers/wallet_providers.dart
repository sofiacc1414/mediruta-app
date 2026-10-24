import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../usuarios/presentation/providers/usuario_providers.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/obtener_wallet_periodo_usecase.dart';
import '../../domain/usecases/obtener_wallet_usecase.dart';

/// Cableado de dependencias de la billetera (Módulo 3) — mismo
/// espíritu que `solicitud_providers.dart`.
final walletRemoteDatasourceProvider = Provider<WalletRemoteDatasource>((ref) {
  return WalletRemoteDatasource(ref.watch(apiClientProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(walletRemoteDatasourceProvider));
});

final obtenerWalletUseCaseProvider = Provider(
  (ref) => ObtenerWalletUseCase(ref.watch(walletRepositoryProvider)),
);

final obtenerWalletPeriodoUseCaseProvider = Provider(
  (ref) => ObtenerWalletPeriodoUseCase(ref.watch(walletRepositoryProvider)),
);
