/// Product codes supported by SIM Partner API v1 for subscription.
abstract final class SimApiProducts {
  static const relaxmoto = 'relaxmoto';
  static const relaxauto = 'relaxauto';
  static const relaxaccidentsFraisMedicaux = 'relaxaccidents_fraismedicaux';

  static const subscriptionSupported = {
    relaxmoto,
    relaxauto,
    relaxaccidentsFraisMedicaux,
  };
}

abstract final class SimApiFormules {
  static const mensuel = 'mensuel';
  static const annuel = 'annuel';
}
