/// URLs suportadas para QR code / links externos:
///
/// - `artour://hybrid` ou `artour://tour` → AR híbrido (fluxo principal do tour)
/// - `artour://ar` → AR legado (image tracking)
/// - `artour://` ou `artour://home` → tela inicial
///
/// Qualquer outro host em `artour://` cai no AR híbrido por defeito (atalho único para visitantes).
enum DeepLinkTarget {
  home,
  hybridAr,
  legacyAr,
}

DeepLinkTarget parseDeepLink(Uri? uri) {
  if (uri == null) return DeepLinkTarget.home;

  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'artour') return DeepLinkTarget.home;

  final host = uri.host.toLowerCase();
  if (host.isEmpty || host == 'home') return DeepLinkTarget.home;
  if (host == 'ar' || host == 'legacy') return DeepLinkTarget.legacyAr;
  if (host == 'hybrid' || host == 'tour') return DeepLinkTarget.hybridAr;

  // artour://qualquer-outra-coisa → abrir tour (comportamento útil para QR genérico)
  return DeepLinkTarget.hybridAr;
}

String initialRouteFromTarget(DeepLinkTarget target) {
  switch (target) {
    case DeepLinkTarget.home:
      return '/';
    case DeepLinkTarget.hybridAr:
      return '/hybrid';
    case DeepLinkTarget.legacyAr:
      return '/ar';
  }
}
