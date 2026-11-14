<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class BuscarVitrinaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return ['buscar' => ['nullable', 'string', 'max:100'], 'categoria' => ['nullable', 'integer', 'min:1'], 'pagina' => ['nullable', 'integer', 'min:1']];
    }

    public function messages(): array
    {
        return ['buscar.max' => 'La búsqueda admite hasta 100 caracteres.', 'buscar.string' => 'Escribe una palabra para buscar.', 'categoria.integer' => 'Elige una categoría válida.', 'categoria.min' => 'Elige una categoría válida.', 'pagina.integer' => 'La página debe ser un número entero.', 'pagina.min' => 'La página debe ser mayor que cero.'];
    }
}
