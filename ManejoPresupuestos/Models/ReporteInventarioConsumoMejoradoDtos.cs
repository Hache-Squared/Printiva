using System;
using System.Collections.Generic;

namespace ManejoPresupuestos.Models
{
    public class ReporteInventarioConsumoMejoradoViewModel
    {
        // filtros
        public DateTime? Desde { get; set; }
        public DateTime? Hasta { get; set; }
        public int? PedidoId { get; set; }
        public int? ProductoId { get; set; }
        public int? RecetaId { get; set; }
        public int? InventarioId { get; set; }
        public string Periodo { get; set; } = "month"; // day|week|month
        public int TopN { get; set; } = 10;
        public string? Q { get; set; }

        // data
        public ReporteInventarioConsumoKpiDto Totales { get; set; } = new();
        public List<ReporteInventarioConsumoTopInsumoDto> TopInsumos { get; set; } = new();
        public List<ReporteInventarioConsumoPorProductoDto> PorProducto { get; set; } = new();
        public List<ReporteInventarioConsumoPorPedidoDto> PorPedido { get; set; } = new();
        public List<ReporteInventarioConsumoPorRecetaDto> PorReceta { get; set; } = new();
        public List<ReporteInventarioConsumoTopPeriodoDto> TopPorPeriodo { get; set; } = new();
        public List<ReporteInventarioConsumoDetalleDto> Detalle { get; set; } = new();

        // desglose tarifas
        public List<ReporteInventarioConsumoTarifaDetalleDto> TarifasDetalle { get; set; } = new();

        // catálogos para filtros
        public List<CatalogoSimpleDto> CatProductos { get; set; } = new();
        public List<CatalogoRecetaDto> CatRecetas { get; set; } = new();
        public List<CatalogoInsumoDto> CatInsumos { get; set; } = new();

        // helper para vista: key = "{ProduccionItemId}|{InventarioId}"
        public Dictionary<string, List<ReporteInventarioConsumoTarifaDetalleDto>> TarifasPorKey { get; set; }
            = new Dictionary<string, List<ReporteInventarioConsumoTarifaDetalleDto>>();
    }

    public class ReporteInventarioConsumoKpiDto
    {
        public int Movimientos { get; set; }
        public int ProduccionItems { get; set; }
        public int Pedidos { get; set; }
        public int Productos { get; set; }
        public int Recetas { get; set; }
        public int Insumos { get; set; }

        public decimal CantidadTotal { get; set; }

        public decimal CostoInsumosEstimado { get; set; }
        public decimal CostoMaterialTotal { get; set; }
        public decimal CostoMaterialGlobal { get; set; }

        public decimal VentaItemsEstimada { get; set; }
        public decimal? RatioCostoSobreVentaItems { get; set; }
    }

    public class ReporteInventarioConsumoTopInsumoDto
    {
        public int InventarioId { get; set; }
        public string InsumoNombre { get; set; } = "";
        public string UnidadNombre { get; set; } = "";

        public decimal CantidadTotal { get; set; }
        public decimal CostoTotalEstimado { get; set; }

        public int Pedidos { get; set; }
        public int Productos { get; set; }
    }

    public class ReporteInventarioConsumoPorProductoDto
    {
        public int ProductoId { get; set; }
        public string ProductoNombre { get; set; } = "";

        public decimal? CantidadTotal { get; set; }
        public decimal? CostoInsumosEstimado { get; set; }

        public decimal CostoMaterialTotal { get; set; }
        public decimal VentaItemsEstimada { get; set; }

        public int Pedidos { get; set; }
        public int ProduccionItems { get; set; }
        public int Recetas { get; set; }
    }

    public class ReporteInventarioConsumoPorPedidoDto
    {
        public int PedidoId { get; set; }
        public string ClienteNombre { get; set; } = "";
        public DateTime PedidoFechaCreacion { get; set; }
        public decimal PedidoTotalEstimado { get; set; }

        public decimal? CantidadTotal { get; set; }
        public decimal? CostoInsumosEstimado { get; set; }

        public decimal CostoMaterialTotal { get; set; }
        public decimal VentaItemsEstimada { get; set; }

        public decimal? RatioCostoSobreVentaItems { get; set; }
    }

    public class ReporteInventarioConsumoPorRecetaDto
    {
        public int? RecetaId { get; set; }
        public string RecetaNombre { get; set; } = "";
        public int ProductoId { get; set; }
        public string ProductoNombre { get; set; } = "";

        public decimal? CantidadTotal { get; set; }
        public decimal? CostoInsumosEstimado { get; set; }

        public decimal CostoMaterialTotal { get; set; }

        public int ProduccionItems { get; set; }
        public int Pedidos { get; set; }
    }

    public class ReporteInventarioConsumoTopPeriodoDto
    {
        public DateTime PeriodoInicio { get; set; }
        public int InventarioId { get; set; }
        public string InsumoNombre { get; set; } = "";
        public string UnidadNombre { get; set; } = "";

        public decimal CantidadTotal { get; set; }
        public decimal CostoTotalEstimado { get; set; }
    }

    public class ReporteInventarioConsumoDetalleDto
    {
        public int ProduccionInventarioConsumoId { get; set; }
        public DateTime FechaConsumo { get; set; }

        public int PedidoId { get; set; }
        public string ClienteNombre { get; set; } = "";
        public int PedidoItemId { get; set; }
        public int ProduccionItemId { get; set; }

        public int ProductoId { get; set; }
        public string ProductoNombre { get; set; } = "";

        public int? RecetaId { get; set; }
        public string RecetaNombre { get; set; } = "";

        public int InventarioId { get; set; }
        public string InsumoNombre { get; set; } = "";
        public string UnidadNombre { get; set; } = "";

        public decimal CantidadConsumida { get; set; }

        // ⚠️ ahora significa "costo unit por tarifas" para ese insumo
        public decimal CostoUnitarioActual { get; set; }
        public decimal CostoTotalEstimado { get; set; }

        public decimal CostoMaterialTotalItem { get; set; }
        public decimal CostoMaterialGlobalItem { get; set; }

        public decimal VentaItemEstimada { get; set; }
        public decimal PedidoTotalEstimado { get; set; }

        public int? DesdeEstatusId { get; set; }
        public int? HaciaEstatusId { get; set; }
        public string? Notas { get; set; }
        public decimal CostoGlobalAplicado { get; set; }
        public decimal CostoTotalConGlobal { get; set; }
        public decimal CostoUnitarioConGlobal { get; set; }
    }

    public class ReporteInventarioConsumoTarifaDetalleDto
    {
        public int ProduccionItemId { get; set; }
        public int ProduccionCosteoId { get; set; }
        public DateTime FechaCosteo { get; set; }

        public string ConceptoCodigo { get; set; } = "";
        public string ConceptoNombre { get; set; } = "";
        public string? ConceptoUnidad { get; set; }

        public int InventarioId { get; set; } // 0 = global/otros
        public int? ImpresoraId { get; set; }

        public int TarifaId { get; set; }
        public string TarifaNombre { get; set; } = "";
        public int TarifaOrden { get; set; }

        public decimal MontoTarifa { get; set; }
        public decimal Cantidad { get; set; }
        public decimal Subtotal { get; set; }
        public string Moneda { get; set; } = "MXN";
    }

    public class CatalogoSimpleDto
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = "";
    }

    public class CatalogoRecetaDto : CatalogoSimpleDto
    {
        public int ProductoId { get; set; }
    }

    public class CatalogoInsumoDto : CatalogoSimpleDto
    {
        public string? UnidadNombre { get; set; }
    }
}