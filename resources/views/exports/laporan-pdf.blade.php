<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>{{ $judul }}</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; font-size: 11px; }
        h1 { color: #0D47A1; font-size: 18px; }
        table { width: 100%; border-collapse: collapse; margin-top: 16px; }
        th { background: #0D47A1; color: white; padding: 8px; text-align: left; }
        td { border: 1px solid #ddd; padding: 6px; }
        tr:nth-child(even) { background: #f5f5f5; }
    </style>
</head>
<body>
    <h1>{{ $judul }}</h1>
    <p>Dicetak: {{ now()->format('d/m/Y H:i') }}</p>
    <table>
        <thead>
            <tr>
                <th>No</th>
                <th>Kode</th>
                <th>Nama Barang</th>
                <th>Ruangan</th>
                <th>Tahun</th>
                <th>Kondisi</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            @foreach($barang as $i => $b)
            <tr>
                <td>{{ $i + 1 }}</td>
                <td>{{ $b->kode_barang }}</td>
                <td>{{ $b->nama_barang }}</td>
                <td>{{ $b->lokasi_ruangan }}</td>
                <td>{{ $b->tahun_pembelian }}</td>
                <td>{{ $b->kondisi_barang }}</td>
                <td>{{ $b->status }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>
