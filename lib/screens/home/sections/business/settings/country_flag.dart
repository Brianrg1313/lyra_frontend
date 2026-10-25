import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/country_model.dart';
import 'package:app/toolkit/lan/image.dart';

/// A country's flag, the size of a row.
///
/// The icon doesn't ship with the app: it's a platform file that arrives as an
/// id in the countries catalog, so it's downloaded from where `/init` said (see
/// [CountryModel.flagUrl]). That's what lets a new region be enabled without
/// shipping a release: the flag arrives with the row.
///
/// A country without a loaded flag —or one that can't be downloaded, or the
/// catalog without a base yet— leaves its slot empty and not a broken sign: the
/// list is still read by name, which is the data. The slot is kept occupied so
/// the list's options stay aligned with each other.
class CountryFlag extends StatelessWidget {
  const CountryFlag({super.key, required this.country, this.size});

  final CountryModel country;

  /// Height of the flag. By default the height of a text row.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final height = size ?? AppSize.text;

    // Nearly all flags are 4:3. The width is reserved in full even if the
    // image doesn't download: without that, the list fits itself differently
    // in each row.
    final width = height * 4 / 3;
    final url = country.flagUrl(width.round());

    return SizedBox(
      width: width,
      height: height,
      child: url.isEmpty ? null : ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.gap / 2),
        child: Image(
          image: mediaImage(url),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const SizedBox.shrink()
        )
      )
    );
  }
}
