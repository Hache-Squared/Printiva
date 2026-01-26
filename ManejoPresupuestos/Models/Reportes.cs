namespace ManejoPresupuestos.Models
{
    public class ReporteConsumoRow
    {
        public DateTime Fecha { get; set; }
        public int? PedidoId { get; set; }
        public int? PedidoItemId { get; set; }
        public int? ProduccionItemId { get; set; }
        public int UsuarioId { get; set; }

        public int? ProductoId { get; set; }
        public int? CantidadItem { get; set; }

        public int? RecetaId { get; set; }
        public string? RecetaNombre { get; set; }

        public int InventarioId { get; set; }
        public string? InsumoNombre { get; set; }
        public string? UnidadNombre { get; set; }

        public decimal Cantidad { get; set; }
        public decimal? DisponibleAntes { get; set; }
        public decimal? DisponibleDespues { get; set; }

        public int? DesdeEstatusId { get; set; }
        public string? DesdeEstatusNombre { get; set; }
        public int? HaciaEstatusId { get; set; }
        public string? HaciaEstatusNombre { get; set; }

        public string? Notas { get; set; }
    }

    public class ReporteConsumoTotales
    {
        public int Movimientos { get; set; }
        public int Pedidos { get; set; }
        public int Insumos { get; set; }
        public decimal? TotalConsumido { get; set; }
    }

    public class ReporteConsumoTopInsumo
    {
        public int InventarioId { get; set; }
        public string? InsumoNombre { get; set; }
        public string? UnidadNombre { get; set; }
        public decimal Consumido { get; set; }
        public int Movimientos { get; set; }
    }

    public class ReporteConsumoViewModel
    {
        public DateTime Desde { get; set; }
        public DateTime Hasta { get; set; }
        public int? PedidoId { get; set; }
        public int? InventarioId { get; set; }
        public int? UsuarioId { get; set; }
        public int? ProductoId { get; set; }
        public int? RecetaId { get; set; }

        public ReporteConsumoTotales Totales { get; set; } = new();
        public List<ReporteConsumoTopInsumo> TopInsumos { get; set; } = new();
        public List<ReporteConsumoRow> Rows { get; set; } = new();
    }

    public class ReporteProduccionEstatusRow
    {
        public int ProduccionEstatusId { get; set; }
        public string Nombre { get; set; } = "";
        public int Orden { get; set; }
        public int Items { get; set; }
    }

    public class ReportePedidoEstatusRow
    {
        public int PedidoEstatusId { get; set; }
        public string Nombre { get; set; } = "";
        public int Pedidos { get; set; }
    }

    public class ReporteProduccionWipRow
    {
        public int ItemsTotales { get; set; }
        public int ItemsWIP { get; set; }
    }

    public class ReporteProduccionViewModel
    {
        public List<ReporteProduccionEstatusRow> ItemsPorEstatus { get; set; } = new();
        public List<ReportePedidoEstatusRow> PedidosPorEstatus { get; set; } = new();
        public ReporteProduccionWipRow Wip { get; set; } = new();
    }

    public class ReporteCosteoPedidoRow
    {
        public int PedidoId { get; set; }
        public string? ClienteNombre { get; set; }
        public decimal? TotalEstimado { get; set; }
        public decimal? CostoReal { get; set; }
        public decimal? Diferencia { get; set; }
        public DateTime? PrimerConsumo { get; set; }
        public DateTime? UltimoConsumo { get; set; }
    }

    public class ReporteCosteoDetalleRow
    {
        public int InventarioId { get; set; }
        public string? InsumoNombre { get; set; }
        public string? UnidadNombre { get; set; }
        public decimal Cantidad { get; set; }
        public decimal CostoUnitario { get; set; }
        public decimal CostoTotal { get; set; }
    }

    public class ReporteCosteoViewModel
    {
        public DateTime Desde { get; set; }
        public DateTime Hasta { get; set; }
        public int? PedidoId { get; set; }
        public List<ReporteCosteoPedidoRow> Pedidos { get; set; } = new();
        public List<ReporteCosteoDetalleRow> Detalle { get; set; } = new();
    }
}
