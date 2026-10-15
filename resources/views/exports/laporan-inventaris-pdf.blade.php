<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <title>Laporan Inventaris SIPERIN</title>
    <style>
        @page { margin: 24px 24px 42px; }
        body { font-family: DejaVu Sans, sans-serif; font-size: 9px; color: #202124; }
        h1 { color: #0D47A1; font-size: 17px; margin: 0 0 8px; }
        .meta { margin: 3px 0; }
        .summary { width: 100%; border-collapse: collapse; margin: 12px 0; }
        .summary td { border: 1px solid #cfd8dc; padding: 5px; }
        .summary td:first-child { font-weight: bold; width: 45%; }
        .items { width: 100%; border-collapse: collapse; margin-top: 10px; }
        .items thead { display: table-header-group; }
        .items th { background: #0D47A1; color: white; padding: 5px 3px; text-align: left; }
        .items td { border: 1px solid #cfd8dc; padding: 4px 3px; vertical-align: top; }
        .items tr:nth-child(even) { background: #f4f7fa; }
    </style>
</head>
<body>
    <h1>Laporan Inventaris SIPERIN</h1>
    <p class="meta">Periode pencatatan:
        {{ $report['period'] === 'all' ? 'Semua data inventaris' : $report['date_from'].' s.d. '.$report['date_to'] }}
    </p>
    <p class="meta">Dibuat: {{ $report['generated_at'] }}</p>

    <table class="summary">
        <tbody>
            <tr><td>Total entri inventaris</td><td>{{ number_format($report['summary']['total_entries'], 0, ',', '.') }}</td></tr>
            <tr><td>Total kuantitas barang</td><td>{{ number_format($report['summary']['total_quantity'], 0, ',', '.') }}</td></tr>
            <tr><td>Total nilai inventaris (harga beli x jumlah)</td><td>Rp {{ number_format($report['summary']['total_value'], 2, ',', '.') }}</td></tr>
            @foreach($report['summary']['conditions'] as $condition => $counts)
                <tr><td>Kondisi {{ $condition }} (entri)</td><td>{{ number_format($counts['entries'], 0, ',', '.') }}</td></tr>
                <tr><td>Kondisi {{ $condition }} (kuantitas)</td><td>{{ number_format($counts['quantity'], 0, ',', '.') }}</td></tr>
            @endforeach
        </tbody>
    </table>

    <table class="items">
        <thead>
            <tr>
                <th>No</th><th>Nama Barang</th><th>Merek</th><th>Nomor Seri</th>
                <th>Ukuran</th><th>Bahan</th><th>Tahun</th><th>Kode</th>
                <th>Jumlah</th><th>Harga Beli (Rp/unit)</th><th>Kondisi</th>
                <th>Kategori</th><th>Lokasi</th><th>Status</th><th>Status Perawatan</th><th>Keterangan</th>
            </tr>
        </thead>
        <tbody>
            @forelse($report['items'] as $index => $item)
                <tr>
                    <td>{{ $index + 1 }}</td>
                    <td>{{ $item['nama_barang'] }}</td>
                    <td>{{ $item['merek'] ?? '-' }}</td>
                    <td>{{ $item['nomor_seri'] ?? '-' }}</td>
                    <td>{{ $item['ukuran'] ?? '-' }}</td>
                    <td>{{ $item['bahan'] ?? '-' }}</td>
                    <td>{{ $item['tahun_pembelian'] }}</td>
                    <td>{{ $item['kode_barang'] }}</td>
                    <td>{{ number_format($item['jumlah_barang'], 0, ',', '.') }}</td>
                    <td>Rp {{ number_format((float) $item['harga_beli'], 2, ',', '.') }}</td>
                    <td>{{ $item['kondisi_barang'] }}</td>
                    <td>{{ $item['kategori'] ?? '-' }}</td>
                    <td>{{ $item['lokasi_ruangan'] ?? '-' }}</td>
                    <td>{{ $item['status'] ?? '-' }}</td>
                    <td>{{ $item['status_perawatan'] ?? '-' }}</td>
                    <td>{{ $item['keterangan'] ?? '-' }}</td>
                </tr>
            @empty
                <tr><td colspan="16">Tidak ada data inventaris pada periode ini.</td></tr>
            @endforelse
        </tbody>
    </table>
</body>
</html>
