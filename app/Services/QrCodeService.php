<?php

namespace App\Services;

use App\Models\Barang;
use chillerlan\QRCode\Output\QRMarkupSVG;
use chillerlan\QRCode\QRCode;
use chillerlan\QRCode\QROptions;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class QrCodeService
{
    public function generateForBarang(Barang $barang): ?string
    {
        try {
            $options = new QROptions([
                'outputInterface' => QRMarkupSVG::class,
                'scale' => 5,
                'svgAddXmlHeader' => false,
            ]);

            $qr = new QRCode($options);
            $content = $qr->render('SIPERIN:'.$barang->kode_barang);
            $path = 'qr/'.$barang->kode_barang.'.svg';

            Storage::disk('public')->put($path, $content);
            $barang->update(['qr_code_path' => $path]);

            return $path;
        } catch (\Throwable $e) {
            Log::warning('QR Code gagal dibuat', [
                'barang_id' => $barang->id,
                'error' => $e->getMessage(),
            ]);

            return null;
        }
    }

    public function getSvgContent(Barang $barang): string
    {
        if ($barang->qr_code_path && Storage::disk('public')->exists($barang->qr_code_path)) {
            return Storage::disk('public')->get($barang->qr_code_path);
        }

        $path = $this->generateForBarang($barang);

        if ($path && Storage::disk('public')->exists($path)) {
            return Storage::disk('public')->get($path);
        }

        return '';
    }
}
