enum MapProvider {
  locationIQ,
  openStreetMap,
  cartoDark,
  cartoLight;

  static const String locationIQToken = 'pk.b5498eed1aef9d81027b4c3ff2032802';

  String get tileUrl {
    switch (this) {
      case MapProvider.locationIQ:
        return 'https://tiles.locationiq.com/v3/streets/r/{z}/{x}/{y}.png?key=$locationIQToken';
      case MapProvider.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapProvider.cartoDark:
        return 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case MapProvider.cartoLight:
        return 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
    }
  }

  String get label {
    switch (this) {
      case MapProvider.locationIQ:
        return 'LocationIQ';
      case MapProvider.openStreetMap:
        return 'OpenStreetMap';
      case MapProvider.cartoDark:
        return 'Carto Dark';
      case MapProvider.cartoLight:
        return 'Carto Light';
    }
  }

  String get attribution => switch (this) {
    MapProvider.locationIQ => 'OpenStreetMap contributors, LocationIQ',
    MapProvider.openStreetMap => 'OpenStreetMap contributors',
    MapProvider.cartoDark || MapProvider.cartoLight =>
      'OpenStreetMap contributors, CARTO',
  };
}
