class Country {
  const Country(this.name, this.dialCode, this.flag);
  final String name;
  final String dialCode;
  final String flag;
}

const countries = <Country>[
  Country('Nigeria', '+234', '🇳🇬'),
  Country('Ghana', '+233', '🇬🇭'),
  Country('Kenya', '+254', '🇰🇪'),
  Country('South Africa', '+27', '🇿🇦'),
  Country('United Kingdom', '+44', '🇬🇧'),
  Country('United States', '+1', '🇺🇸'),
  Country('Canada', '+1', '🇨🇦'),
];

const nigerianStates = <String>[
  'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue', 'Borno',
  'Cross River', 'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu', 'FCT Abuja', 'Gombe',
  'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi', 'Kogi', 'Kwara', 'Lagos',
  'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 'Plateau', 'Rivers', 'Sokoto',
  'Taraba', 'Yobe', 'Zamfara',
];
