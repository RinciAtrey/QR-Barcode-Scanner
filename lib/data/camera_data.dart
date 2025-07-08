enum CameraFacingOption { back, front }

extension CameraFacingOptionX on CameraFacingOption {
  String get key => this == CameraFacingOption.back ? 'back' : 'front';
  static CameraFacingOption fromKey(String k) =>
      k == CameraFacingOption.front.key
          ? CameraFacingOption.front
          : CameraFacingOption.back;
}



