<?php

namespace App\Filament\Resources;

use App\Filament\Actions\ResultadoModeracion;
use App\Filament\Resources\TiendaResource\Pages\ListarTiendas;
use App\Models\Tienda;
use App\Support\ModeracionTiendas;
use Filament\Actions\Action;
use Filament\Facades\Filament;
use Filament\Forms\Components\Textarea;
use Filament\Resources\Resource;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class TiendaResource extends Resource
{
    protected static ?string $model = Tienda::class;

    protected static ?string $slug = 'tiendas';

    protected static ?string $modelLabel = 'tienda';

    protected static ?string $pluralModelLabel = 'tiendas';

    private const ESTADOS = ['activa' => 'Activa', 'dada_de_baja' => 'Dada de baja'];

    public static function table(Table $table): Table
    {
        return $table->defaultSort('nombre')
            ->columns([
                TextColumn::make('nombre')->searchable(),
                TextColumn::make('estado')->badge()->formatStateUsing(fn (string $state) => self::ESTADOS[$state]),
                TextColumn::make('vigencia.plan')->label('Plan')->formatStateUsing(fn (string $state) => ucfirst($state)),
                TextColumn::make('categorias.nombre')->label('Categorías')->listWithLineBreaks(),
                TextColumn::make('motivo_baja')->label('Motivo de baja')->wrap(),
            ])
            ->filters([
                SelectFilter::make('estado')->options(self::ESTADOS),
                SelectFilter::make('plan')->options(['gratis' => 'Gratis', 'premium' => 'Premium'])
                    ->query(fn (Builder $query, array $data) => blank($data['value'] ?? null)
                        ? $query : $query->whereHas('vigencia', fn (Builder $vigencia) => $vigencia->where('plan', $data['value']))),
                SelectFilter::make('categorias')->label('Categoría')->relationship('categorias', 'nombre'),
            ])
            ->recordActions([
                Action::make('baja')->label('Dar de baja')->color('danger')
                    ->visible(fn (Tienda $record) => $record->estado === 'activa')
                    ->modalDescription('La tienda saldrá de la Vitrina y se cancelarán sus pedidos pendientes.')
                    ->schema([Textarea::make('motivo')->label('Motivo visible para el vendedor')->required()->maxLength(500)])
                    ->action(fn (Tienda $record, array $data, ModeracionTiendas $moderacion) => ResultadoModeracion::ejecutar(
                        fn () => $moderacion->darDeBaja(Filament::auth()->user(), $record->id, $data['motivo']), 'Tienda dada de baja',
                    )),
                Action::make('reactivar')->label('Reactivar')->requiresConfirmation()
                    ->visible(fn (Tienda $record) => $record->estado === 'dada_de_baja')
                    ->modalDescription('La tienda vuelve a la Vitrina. Los pedidos cancelados conservan su estado.')
                    ->action(fn (Tienda $record, ModeracionTiendas $moderacion) => ResultadoModeracion::ejecutar(
                        fn () => $moderacion->reactivar(Filament::auth()->user(), $record->id), 'Tienda reactivada',
                    )),
            ]);
    }

    public static function getPages(): array
    {
        return ['index' => ListarTiendas::route('/')];
    }
}
