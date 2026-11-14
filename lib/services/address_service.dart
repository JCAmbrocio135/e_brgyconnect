import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressItem {
  final String code;
  final String name;
  final String type; // Mun, City, SubMun
  final bool isRegion; // true only for the Metro Manila (NCR) entry
  const AddressItem(
    this.code,
    this.name, {
    this.type = '',
    this.isRegion = false,
  });
}

class AddressService {
  AddressService._();
  static final instance = AddressService._();

  // If the API host changes, edit only this line and the paths below.
  static const _base = 'https://psgc.cloud/api';

  List<AddressItem>? _ncrCache; // NCR list is big, so load it once

  // The server double-encodes some letters (e.g. "Ã±" instead of "ñ").
  // This converts them back, and leaves normal text alone.
  String _fix(String s) {
    try {
      return utf8.decode(latin1.encode(s)).trim();
    } catch (_) {
      return s.trim();
    }
  }

  // Sort ignoring the "City of " prefix so lists read naturally
  String _key(String n) => n.replaceFirst('City of ', '').toLowerCase();

  Future<List<AddressItem>> _get(String path) async {
    final res = await http
        .get(Uri.parse('$_base/$path'))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Server returned ${res.statusCode}');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final list = body is List ? body : (body['data'] as List);
    final items = list
        .map((e) => AddressItem(
              e['code'].toString(),
              _fix(e['name'].toString()),
              type: (e['type'] ?? '').toString(),
            ))
        .toList();
    items.sort((a, b) => _key(a.name).compareTo(_key(b.name)));
    return items;
  }

  /// All provinces, plus one "Metro Manila (NCR)" entry.
  Future<List<AddressItem>> provincesAndNcr() async {
    final regions = await _get('regions');
    final ncr = regions.firstWhere(
      (r) => r.name.contains('NCR') || r.name.contains('National Capital'),
    );
    final ncrPrefix = ncr.code.substring(0, 2);

    final provinces = (await _get('provinces'))
        .where((p) => !p.code.startsWith(ncrPrefix))
        .toList();

    provinces.add(AddressItem(ncr.code, 'Metro Manila (NCR)', isRegion: true));
    provinces.sort((a, b) => _key(a.name).compareTo(_key(b.name)));
    return provinces;
  }

  /// Cities of a province, or of Metro Manila.
  Future<List<AddressItem>> cities(AddressItem place) async {
    if (!place.isRegion) {
      return _get('provinces/${place.code}/cities-municipalities');
    }

    if (_ncrCache != null) return _ncrCache!;

    // NCR: read all cities and keep those with NCR's code prefix ("13")
    final prefix = place.code.substring(0, 2);
    final all = await _get('cities-municipalities');

    final ncr = <AddressItem>[];
    for (final c in all.where((c) => c.code.startsWith(prefix))) {
      if (c.name == 'City of Manila') continue; // its barangays are in the districts
      if (c.type == 'SubMun') {
        ncr.add(AddressItem(c.code, 'Manila - ${c.name}', type: c.type));
      } else {
        ncr.add(c);
      }
    }
    if (ncr.isEmpty) throw Exception('NCR cities not found');
    ncr.sort((a, b) => _key(a.name).compareTo(_key(b.name)));
    return _ncrCache = ncr;
  }

  Future<List<AddressItem>> barangays(AddressItem city) async {
    final paths = [
      'cities-municipalities/${city.code}/barangays',
      'sub-municipalities/${city.code}/barangays', // for Manila's districts
    ];
    for (final p in paths) {
      try {
        final items = await _get(p);
        if (items.isNotEmpty) return items;
      } catch (_) {}
    }
    throw Exception('No barangays found');
  }
}