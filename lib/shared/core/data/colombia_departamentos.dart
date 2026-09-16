/// Departamentos de Colombia y sus municipios/ciudades principales, para
/// el selector con autocompletar de HU-02 (perfil del paciente) — antes
/// eran dos campos de texto libre, lo que dejaba pasar de todo (nombres
/// mal escritos, acentos corruptos por encoding del shell al cargar
/// datos de prueba — ver ESQUEMA.md, "Nota de troubleshooting real" — o
/// directamente lugares/instituciones en vez de una ciudad real), y eso
/// rompía en silencio la geocodificación de Nominatim más adelante.
///
/// No es el listado completo y oficial de los 1122 municipios de la
/// DIVIPOLA — sería poco práctico de mantener a mano y no aporta mucho
/// más que la cobertura real de dónde MediRuta opera hoy. Cubre los 32
/// departamentos + Bogotá D.C. (tratada como su propio "departamento",
/// convención común en formularios colombianos) con las ciudades y
/// municipios más relevantes de cada uno. Si hace falta un municipio que
/// no está, se agrega acá — una sola fuente de verdad para todo el
/// selector.
const Map<String, List<String>> colombiaDepartamentosCiudades = {
  'Bogotá D.C.': ['Bogotá'],
  'Amazonas': ['Leticia', 'Puerto Nariño'],
  'Antioquia': [
    'Medellín', 'Bello', 'Itagüí', 'Envigado', 'Sabaneta', 'La Estrella',
    'Caldas', 'Copacabana', 'Girardota', 'Barbosa', 'Rionegro', 'Marinilla',
    'La Ceja', 'El Retiro', 'Guarne', 'Turbo', 'Apartadó', 'Chigorodó',
    'Caucasia', 'Yarumal', 'Santa Fe de Antioquia', 'Sonsón', 'Amagá',
  ],
  'Arauca': ['Arauca', 'Saravena', 'Tame', 'Arauquita'],
  'Atlántico': [
    'Barranquilla', 'Soledad', 'Malambo', 'Sabanalarga', 'Puerto Colombia',
    'Galapa', 'Baranoa',
  ],
  'Bolívar': [
    'Cartagena', 'Magangué', 'Turbaco', 'Arjona', 'El Carmen de Bolívar',
    'Mompós',
  ],
  'Boyacá': [
    'Tunja', 'Duitama', 'Sogamoso', 'Chiquinquirá', 'Paipa', 'Villa de Leyva',
    'Puerto Boyacá',
  ],
  'Caldas': [
    'Manizales', 'La Dorada', 'Chinchiná', 'Villamaría', 'Riosucio',
    'Anserma',
  ],
  'Caquetá': ['Florencia', 'San Vicente del Caguán', 'Puerto Rico'],
  'Casanare': ['Yopal', 'Aguazul', 'Villanueva', 'Tauramena'],
  'Cauca': [
    'Popayán', 'Santander de Quilichao', 'Puerto Tejada', 'Patía',
    'El Bordo',
  ],
  'Cesar': [
    'Valledupar', 'Aguachica', 'Codazzi', 'La Jagua de Ibirico', 'Bosconia',
  ],
  'Chocó': ['Quibdó', 'Istmina', 'Condoto', 'Tadó'],
  'Córdoba': [
    'Montería', 'Cereté', 'Sahagún', 'Lorica', 'Planeta Rica', 'Montelíbano',
  ],
  'Cundinamarca': [
    'Soacha', 'Chía', 'Zipaquirá', 'Facatativá', 'Fusagasugá', 'Girardot',
    'Mosquera', 'Madrid', 'Funza', 'Cajicá', 'Cota', 'Sopó', 'La Calera',
    'Ubaté',
  ],
  'Guainía': ['Inírida'],
  'Guaviare': ['San José del Guaviare'],
  'Huila': ['Neiva', 'Pitalito', 'Garzón', 'La Plata', 'Campoalegre'],
  'La Guajira': ['Riohacha', 'Maicao', 'Uribia', 'Fonseca', 'Villanueva'],
  'Magdalena': [
    'Santa Marta', 'Ciénaga', 'Fundación', 'Aracataca', 'El Banco',
  ],
  'Meta': ['Villavicencio', 'Acacías', 'Granada', 'Puerto López'],
  'Nariño': [
    'Pasto', 'Ipiales', 'Tumaco', 'Túquerres', 'La Unión',
  ],
  'Norte de Santander': [
    'Cúcuta', 'Ocaña', 'Pamplona', 'Villa del Rosario', 'Los Patios',
  ],
  'Putumayo': ['Mocoa', 'Puerto Asís', 'Orito', 'Sibundoy'],
  'Quindío': ['Armenia', 'Calarcá', 'Montenegro', 'La Tebaida', 'Circasia'],
  'Risaralda': [
    'Pereira', 'Dosquebradas', 'Santa Rosa de Cabal', 'La Virginia',
  ],
  'San Andrés y Providencia': ['San Andrés', 'Providencia'],
  'Santander': [
    'Bucaramanga', 'Floridablanca', 'Girón', 'Piedecuesta', 'Barrancabermeja',
    'San Gil', 'Socorro',
  ],
  'Sucre': ['Sincelejo', 'Corozal', 'Sampués', 'San Marcos'],
  'Tolima': [
    'Ibagué', 'Espinal', 'Melgar', 'Honda', 'Chaparral', 'Líbano',
  ],
  'Valle del Cauca': [
    'Cali', 'Palmira', 'Buenaventura', 'Tuluá', 'Cartago', 'Buga',
    'Jamundí', 'Yumbo', 'Candelaria', 'Florida',
  ],
  'Vaupés': ['Mitú'],
  'Vichada': ['Puerto Carreño'],
};

/// Lista de departamentos, orden alfabético — para el dropdown.
final List<String> colombiaDepartamentos =
    colombiaDepartamentosCiudades.keys.toList()..sort();
