/// Texto que acompaña la puntuación (HU-18).
String etiquetaEstrellas(int puntuacion) {
  return switch (puntuacion) {
    1 => 'Muy mala',
    2 => 'Mala',
    3 => 'Regular',
    4 => 'Muy buena',
    5 => 'Excelente',
    _ => '',
  };
}
