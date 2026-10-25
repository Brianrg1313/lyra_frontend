import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/toolkit/lan/image.dart';

// PACKAGES
import 'package:url_launcher/url_launcher.dart';

// SERVICES
import 'package:app/services/files/file_model.dart';
import 'package:app/services/sales/sale_detail_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/sales/sale_format.dart';
import 'package:app/screens/modals/shared/image_viewer/_image_viewer.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **El comprobante: what the customer sent to show the money went out.**
///
/// It is the block the panel is opened for when a sale is standing at "Pago por
/// verificar", and it sits directly under the card that names the sale for the
/// same reason: the button that approves the payment is up there, and nobody
/// should have to scroll past the totals to see what they are approving.
///
/// **Three shapes, and which one is drawn is read off the file and not off the
/// word.** A picture is drawn (`kind: image`), a stored file that is not an
/// image is offered to open (a statement the customer exported as a PDF), and a
/// reference the customer typed is text. The backend's `kind` says what
/// arrived, but an image whose bytes could not be stored arrives as an `image`
/// entry with no file — the description that came with it is then all there is,
/// and saying so is more use than a sale that looks as if nothing was ever
/// sent.
///
/// **All of them, newest first.** A customer who pays in two transfers sends
/// two, and the newest is the one being checked — `payment.proof` on the
/// backend is exactly that entry, so the list is what travels and the panel
/// puts the last of it at the top.
///
/// **Nothing here is a fact this platform checked.** It cannot be: a transfer
/// happens at a bank and a comprobante is a photo on WhatsApp. Half of what a
/// picture's text says is a model describing that photo, and the reference is
/// digits the customer typed — so the block is worded as what was said and
/// shown, and the sale is approved by the person reading it.
class SaleDetailProof extends StatelessWidget {
  const SaleDetailProof({super.key, required this.sale});

  final SaleDetailModel sale;

  /// **Whether this sale is one a comprobante can exist for.**
  ///
  /// It is read from the conversation behind it and never from whether one
  /// arrived: a purchase arranged over a channel that has had nothing sent yet
  /// is precisely the sale somebody needs to be told has nothing on file, and a
  /// ticket rung up at the counter has no conversation at all — a heading over
  /// a question that cannot be asked there is a block that reads as a gap.
  static bool belongsTo(SaleDetailModel sale) =>
    sale.isDeal || sale.chat.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // Newest first: it is the one somebody is about to decide on, and the older
    // ones are the trail behind it.
    final proofs = sale.payment.proofs.reversed
      .where((proof) => !proof.isEmpty)
      .toList();

    return SettingsBlock(
      title: S.of(context).sales_detail_proof,
      subtitle: S.of(context).sales_detail_proof_subtitle,
      child: proofs.isEmpty
        ? _empty(context)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < proofs.length; i++) ...[
                if (i > 0) Separator.horizontal(
                  margin: EdgeInsets.symmetric(vertical: AppSize.spaceS)
                ),
                _Proof(proof: proofs[i])
              ],
              if (proofs.length > 1) ...[
                SizedBox(height: AppSize.spaceS),
                TextSmall(
                  S.of(context).sales_detail_proof_count(proofs.length),
                  color: ThemeColor.of(context).text.secondary
                )
              ]
            ]
          )
    );
  }

  /// Nothing on file, which is an answer and not a gap: it is what somebody
  /// verifying a payment is going to go and look for in the conversation.
  Widget _empty(BuildContext context) => TextSmall(
    S.of(context).sales_detail_proof_empty,
    lines: 2,
    color: ThemeColor.of(context).text.secondary
  );
}

/// One comprobante: what was sent, and what came with it.
class _Proof extends StatelessWidget {
  const _Proof({required this.proof});

  final SaleProofModel proof;

  /// How tall the picture is drawn. A transfer screenshot is a tall phone
  /// capture, so it is given room to be read at a glance without the block
  /// becoming a page of its own — the amount and the date are what somebody is
  /// looking for, and the rest is one tap away in the viewer.
  static double get _preview => AppSize.action * 5;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (proof.isImage) ...[
          _picture(context, proof.file!),
          SizedBox(height: AppSize.spaceS)
        ],
        SettingsList(rows: [
          if (proof.isFile) _file(context, proof.file!),
          // A picture that did not survive is **one** row and not an empty one
          // with the text under it: what was sent is the picture, and the line
          // the pipeline wrote about it is the only reading left of it.
          if (proof.isLostImage) SettingsRow(
            icon: CI.image,
            label: S.of(context).sales_detail_proof_image,
            hint: S.of(context).sales_detail_proof_lost,
            child: TextMedium(
              proof.text.isEmpty ? S.of(context).sales_detail_none : proof.text,
              lines: 3,
              ellipsis: true,
              color: proof.text.isEmpty ? scheme.text.secondary : null
            )
          )
          else if (proof.text.isNotEmpty) SettingsValue(
            icon: CI.chat,
            label: S.of(context).sales_detail_proof_said,
            value: proof.text
          ),
          // Selectable because it is pasted into a banking app to be looked up,
          // which is the whole point of it having been typed out.
          if (proof.reference.isNotEmpty) SettingsValue(
            icon: CI.link,
            label: S.of(context).sales_detail_proof_reference,
            value: proof.reference,
            selectable: true
          ),
          if (proof.at != null) SettingsValue(
            icon: CI.calendar,
            label: S.of(context).sales_detail_proof_at,
            value: saleDateLabel(context, proof.at)
          )
        ])
      ]
    );
  }

  /// The picture, over the page's own surface and whole ([BoxFit.contain]).
  ///
  /// Cropping it to a frame is what a product photo wants and the opposite of
  /// what this one does: the amount and the date sit at the edges of a bank
  /// app's screenshot, and a `cover` fit is a comprobante with its figures cut
  /// off. Touching it opens the full-screen viewer, where it zooms.
  ///
  /// It is asked for at its own address and not at a thumbnail's: what the
  /// customer sends the bot is stored at one size and renders no variants
  /// (purpose `chat`), so there is no smaller rendition to ask for — and a
  /// comprobante is read, not scanned in a grid.
  Widget _picture(BuildContext context, FileModel file) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      message: S.of(context).sales_detail_proof_open,
      action: () => showImageViewer(context, url: file.url),
      height: _preview,
      radius: AppSize.cornerInset(AppSize.gap),
      color: scheme.surface,
      feedbackColor: scheme.line,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap)),
        child: Image(
          image: mediaImage(file.url),
          fit: BoxFit.contain,
          width: double.infinity,
          height: _preview,
          loadingBuilder: (context, child, progress) =>
            progress == null ? child : const Center(child: Loading()),
          // An id that no longer resolves. The entry stays: what came with the
          // picture is still what a person reads.
          errorBuilder: (context, error, stack) => Center(child: Icon(
            CI.image,
            size: AppSize.text * 2,
            color: scheme.text.secondary
          ))
        )
      )
    );
  }

  /// What was sent and is not a picture — a statement the customer exported out
  /// of their banking app. It is offered rather than drawn: this app renders no
  /// documents, and the system already has something that does.
  Widget _file(BuildContext context, FileModel file) => SettingsValue(
    icon: CI.documents,
    label: S.of(context).sales_detail_proof_file,
    value: file.mime,
    action: SettingsAction(
      icon: CI.eye,
      message: S.of(context).sales_detail_proof_file_open,
      action: () => _open(context, file)
    )
  );

  /// Opens the file in whatever the system uses for it.
  ///
  /// That it could not be opened is said: it is the only thing that tells a
  /// file the system has no reader for apart from a touch that did nothing.
  /// Opening is the system's business and can fail for something that is not
  /// the address, which arrives as an exception and is told the same way.
  Future<void> _open(BuildContext context, FileModel file) async {
    bool opened = false;

    final url = Uri.tryParse(file.url);

    if (url != null) {
      try {
        opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (error) {
        if (kDebugMode) print("Could not open the payment proof: $error");
      }
    }

    if (opened || !context.mounted) return;

    FloatFlag.of(context).error(
      message: S.of(context).sales_detail_proof_file_failed
    );
  }
}
