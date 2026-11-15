<?php

namespace App\Filament\Resources;

use App\Filament\Actions\ResultadoModeracion;
use App\Filament\Resources\ReporteResource\Pages\ListarReportes;
use App\Models\Reporte;
use App\Support\ModeracionTiendas;
use Filament\Actions\Action;
use Filament\Facades\Filament;
use Filament\Forms\Components\Textarea;
use Filament\Resources\Resource;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class ReporteResource extends Resource
{
    protected static ?string $model = Reporte::class;

    protected static ?string $slug = 'reportes';

    protected static ?string $modelLabel = 'reporte';

    protected static ?string $pluralModelLabel = 'reportes';

    private const ESTADOS = ['nuevo' => 'Nuevo', 'sin_accion' => 'Sin acción', 'tienda_dada_de_baja' => 'Tienda dada de baja'];

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->with('tienda');
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort(fn (Builder $query) => $query->orderByRaw("CASE WHEN reportes.estado = 'nuevo' THEN 0 ELSE 1 END")->latest('reportes.creado_en'))
            ->columns([
                TextColumn::make('tienda.nombre')->label('Tienda')->searchable(),
                TextColumn::make('motivo')->formatStateUsing(fn (string $state) => Reporte::MOTIVOS[$state]),
                TextColumn::make('estado')->badge()->formatStateUsing(fn (string $state) => self::ESTADOS[$state])
                    ->color(fn (string $state) => match ($state) {
                        'nuevo' => 'warning', 'tienda_dada_de_baja' => 'danger', default => 'gray'
                    }),
                TextColumn::make('creado_en')->label('Recibido')->dateTime('d/m/Y H:i', 'America/Guayaquil'),
            ])
            ->filters([SelectFilter::make('estado')->options(self::ESTADOS)])
            ->recordActions([
                Action::make('detalle')->label('Ver detalle')
                    ->schema([
                        Textarea::make('detalle')->label('Detalle del reporte')->disabled(),
                        Textarea::make('nota_admin')->label('Nota de revisión')->disabled(),
                    ])
                    ->fillForm(fn (Reporte $record) => ['detalle' => $record->detalle ?? 'Sin detalle', 'nota_admin' => $record->nota_admin ?? 'Sin nota'])
                    ->modalSubmitAction(false)->modalCancelActionLabel('Volver'),
                Action::make('cerrar')->label('Cerrar sin acción')->visible(fn (Reporte $record) => $record->estado === 'nuevo')
                    ->schema([Textarea::make('nota')->label('Nota de revisión')->required()->maxLength(500)])
                    ->action(fn (Reporte $record, array $data, ModeracionTiendas $moderacion) => ResultadoModeracion::ejecutar(
                        fn () => $moderacion->cerrar(Filament::auth()->user(), $record, $data['nota']), 'Reporte cerrado',
                    )),
                Action::make('baja')->label('Dar de baja la tienda')->color('danger')
                    ->visible(fn (Reporte $record) => $record->estado === 'nuevo' && $record->tienda?->estado === 'activa')
                    ->modalDescription('La tienda saldrá de la Vitrina y se cancelarán sus pedidos pendientes.')
                    ->schema([Textarea::make('motivo')->label('Motivo visible para el vendedor')->required()->maxLength(500)])
                    ->action(fn (Reporte $record, array $data, ModeracionTiendas $moderacion) => ResultadoModeracion::ejecutar(
                        fn () => $moderacion->darDeBaja(Filament::auth()->user(), $record->tienda_id, $data['motivo'], $record->id), 'Tienda dada de baja',
                    )),
            ]);
    }

    public static function getPages(): array
    {
        return ['index' => ListarReportes::route('/')];
    }
}
