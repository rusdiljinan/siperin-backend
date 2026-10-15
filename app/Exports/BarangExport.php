<?php

namespace App\Exports;

use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class BarangExport implements FromCollection, WithHeadings, WithMapping
{
    public function __construct(protected Collection $barang) {}

    public function collection(): Collection
    {
        return $this->barang;
    }

    public function headings(): array
    {
        return [
            'No',
            'Kode Barang',
            'Nama Barang',
            'Kategori',
            'Ruangan',
            'Tahun',
            'Jumlah',
            'Harga Beli',
            'Kondisi',
            'Status',
        ];
    }

    public function map($barang): array
    {
        static $no = 0;
        $no++;

        return [
            $no,
            $barang->kode_barang,
            $barang->nama_barang,
            $barang->kategori?->nama_kategori,
            $barang->lokasi_ruangan,
            $barang->tahun_pembelian,
            $barang->jumlah_barang,
            $barang->harga_beli,
            $barang->kondisi_barang,
            $barang->status,
        ];
    }
}
