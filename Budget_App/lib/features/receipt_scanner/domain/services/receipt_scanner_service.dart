import '../models/scanned_receipt_result.dart';

/// Clean interface a real OCR backend (Google ML Kit / Cloud Vision / a
/// multimodal LLM) drops in behind later, exactly like AuthRepository does
/// for auth providers.
abstract interface class ReceiptScannerService {
  Future<ScannedReceiptResult> processReceiptImage(String filePathOrBytes);
}
