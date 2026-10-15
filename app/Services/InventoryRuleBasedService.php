<?php

namespace App\Services;

class InventoryRuleBasedService
{
    /**
     * Evaluate scores and return total and condition string.
     *
     * @param array $scores associative array with keys:
     *  kelengkapan_score, fungsional_score, fisik_score, usia_score, perawatan_score, keamanan_score
     * @return array ['total_score' => int, 'condition' => string]
     */
    public function evaluate(array $scores): array
    {
        $keys = [
            'kelengkapan_score',
            'fungsional_score',
            'fisik_score',
            'usia_score',
            'perawatan_score',
            'keamanan_score',
        ];

        $total = 0;
        foreach ($keys as $k) {
            $total += (int) ($scores[$k] ?? 0);
        }

        if ($total >= 15) {
            $condition = 'Sangat Baik';
        } elseif ($total >= 10) {
            $condition = 'Baik';
        } else {
            $condition = 'Rusak';
        }

        return [
            'total_score' => $total,
            'condition' => $condition,
        ];
    }
}
