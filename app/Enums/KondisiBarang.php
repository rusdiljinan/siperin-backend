<?php

namespace App\Enums;

enum KondisiBarang: string
{
    case SangatBaik = 'Sangat Baik';
    case Baik = 'Baik';
    case Rusak = 'Rusak';

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
