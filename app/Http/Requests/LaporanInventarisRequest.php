<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class LaporanInventarisRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'period' => ['required', 'in:all,weekly,monthly,custom'],
            'reference_date' => ['required_if:period,weekly,monthly', 'nullable', 'date_format:Y-m-d'],
            'start_date' => ['required_if:period,custom', 'nullable', 'date_format:Y-m-d'],
            'end_date' => ['required_if:period,custom', 'nullable', 'date_format:Y-m-d'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            if (
                $this->input('period') === 'custom'
                && $this->filled('start_date')
                && $this->filled('end_date')
                && $this->date('start_date') > $this->date('end_date')
            ) {
                $validator->errors()->add('start_date', 'Tanggal mulai tidak boleh setelah tanggal akhir.');
            }
        });
    }
}
