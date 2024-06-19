class Bulan {
  String getMonthName(int month) {
    List<String> monthNames = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return monthNames[month - 1];
  }

  String getMonthNumber(String selectedMonth) {
    Map<String, String> monthNames = {
      'Januari': '01',
      'Februari': '02',
      'Maret': '03',
      'April': '04',
      'Mei': '05',
      'Juni': '06',
      'Juli': '07',
      'Agustus': '08',
      'September': '09',
      'Oktober': '10',
      'November': '11',
      'Desember': '12'
    };
    return monthNames[selectedMonth] ?? '01';
  }
}