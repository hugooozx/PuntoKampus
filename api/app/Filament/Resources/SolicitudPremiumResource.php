<?php

namespace App\Filament\Resources;

use App\Filament\Actions\ResultadoModeracion;
use App\Filament\Resources\SolicitudPremiumResource\Pages\ListarSolicitudes;
use App\Models\SolicitudPremium;
use App\Support\Premium;
use Filament\Actions\Action;
use Filament\Facades\Filament;
use Filament\Forms\Components\Textarea;
use Filament\Resources\Resource;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class SolicitudPremiumResource extends Resource
{
    protected static ?string $model = SolicitudPremium::class;

    protected static ?string $slug = 'solicitudes-premium';

    protected static ?string $modelLabel = 'solicitud Premium';

    protected static ?string $pluralModelLabel = 'solicitudes Premium';

    private const ESTADOS = ['pendiente' => 'Pendiente', 'aprobada' => 'Aprobada', 'rechazada' => 'Rechazada'];

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort(fn (Builder $query) => $query->orderByRaw("CASE WHEN solicitudes_premium.estado = 'pendiente' THEN 0 ELSE 1 END")->latest('solicitudes_premium.creado_en'))
            ->columns([
                TextColumn::make('tienda.nombre')->label('Tienda')->placeholder('Tienda eliminada')->searchable(),
                TextColumn::make('numero_comprobante')->label('Número de comprobante')->searchable(),
                TextColumn::make('monto')->money('USD'),
                TextColumn::make('estado')->badge()->formatStateUsing(fn (string $state) => self::ESTADOS[$state]),
                TextColumn::make('creado_en')->label('Recibida')->dateTime('d/m/Y H:i', 'America/Guayaquil'),
                TextColumn::make('motivo_rechazo')->label('Motivo de rechazo')->wrap(),
            ])
            ->filters([SelectFilter::make('estado')->options(self::ESTADOS)])
            ->recordActions([
                Action::make('foto')->label('Ver comprobante')
                    ->visible(fn (SolicitudPremium $record) => $record->foto_comprobante !== null)
                    ->url(fn (SolicitudPremium $record) => route('admin.comprobantes', $record->id))->openUrlInNewTab(),
                Action::make('aprobar')->label('Aprobar')->requiresConfirmation()
                    ->visible(fn (SolicitudPremium $record) => $record->estado === 'pendiente')
                    ->modalDescription('Comprueba que el pago llegó antes de activar Premium hasta el fin del periodo vigente.')
                    ->action(fn (SolicitudPremium $record, Premium $premium) => ResultadoModeracion::ejecutar(
                        fn () => $premium->revisar(Filament::auth()->user(), $record), 'Premium aprobado',
                    )),
                Action::make('rechazar')->label('Rechazar')->color('danger')
                    ->visible(fn (SolicitudPremium $record) => $record->estado === 'pendiente')
                    ->schema([Textarea::make('motivo')->label('Motivo visible para el vendedor')->required()->maxLength(300)])
                    ->action(fn (SolicitudPremium $record, array $data, Premium $premium) => ResultadoModeracion::ejecutar(
                        fn () => $premium->revisar(Filament::auth()->user(), $record, $data['motivo']), 'Solicitud rechazada',
                    )),
            ]);
    }

    public static function getPages(): array
    {
        return ['index' => ListarSolicitudes::route('/')];
    }
}
