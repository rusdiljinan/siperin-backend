<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class LaporanInventarisExport implements FromArray, ShouldAutoSize, WithStyles
{
    public function __construct(private readonly array $report) {}

    public function array(): array
    {
        $summary = $this->report['summary'];
        $conditions = (array) $summary['conditions'];
        $period = $this->report['period'] === 'all'
            ? 'Semua data inventaris'
            : $this->report['date_from'].' s.d. '.$this->report['date_to'];
        $rows = [
            ['Laporan Inventaris SIPERIN'],
            ['Periode pencatatan', $period],
            ['Dibuat pada', $this->report['generated_at']],
            [],
            ['Ringkasan', 'Nilai'],
            ['Total entri inventaris', $summary['total_entries']],
            ['Total kuantitas barang', $summary['total_quantity']],
            ['Total nilai inventaris (harga beli x jumlah)', $summary['total_value']],
        ];

        foreach ($conditions as $condition => $counts) {
            $rows[] = ["Kondisi {$condition} (entri)", $counts['entries']];
            $rows[] = ["Kondisi {$condition} (kuantitas)", $counts['quantity']];
        }

        $rows[] = [];
        $rows[] = [
            'No',
            'Nama Barang',
            'Merek',
            'Nomor Seri',
            'Ukuran',
            'Bahan',
            'Tahun Pembelian',
            'Kode Barang',
            'Jumlah Barang',
            'Harga Beli (Rp/unit)',
            'Kondisi Barang',
            'Kategori',
            'Lokasi Ruangan',
            'Status',
            'Status Perawatan',
            'Keterangan',
        ];

        foreach ($this->report['items'] as $index => $item) {
            $rows[] = [
                $index + 1,
                $item['nama_barang'],
                $item['merek'],
                $item['nomor_seri'],
                $item['ukuran'],
                $item['bahan'],
                $item['tahun_pembelian'],
                $item['kode_barang'],
                $item['jumlah_barang'],
                $item['harga_beli'],
                $item['kondisi_barang'],
                $item['kategori'],
                $item['lokasi_ruangan'],
                $item['status'],
                $item['status_perawatan'],
                $item['keterangan'],
            ];
        }

        return $rows;
    }

    public function styles(Worksheet $sheet): array
    {
        $headerRow = 8 + count((array) $this->report['summary']['conditions']) * 2;
        $firstDataRow = $headerRow + 1;
        $lastDataRow = $headerRow + count($this->report['items']);

        $sheet->getStyle('B5:B6')->getNumberFormat()->setFormatCode('#,##0');
        $sheet->getStyle('B7')->getNumberFormat()->setFormatCode('"Rp" #,##0.00');

        if ($firstDataRow <= $lastDataRow) {
            $sheet->getStyle("I{$firstDataRow}:I{$lastDataRow}")
                ->getNumberFormat()
                ->setFormatCode('#,##0');
            $sheet->getStyle("J{$firstDataRow}:J{$lastDataRow}")
                ->getNumberFormat()
                ->setFormatCode('"Rp" #,##0.00');
        }

        return [
            1 => ['font' => ['bold' => true, 'size' => 16]],
            5 => ['font' => ['bold' => true]],
            $headerRow => [
                'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
                'fill' => ['fillType' => 'solid', 'startColor' => ['rgb' => '0D47A1']],
            ],
        ];
    }
}
