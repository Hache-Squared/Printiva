namespace ManejoPresupuestos.Models
{
    public class ReportesIndexKpis
    {
        public int PedidosActivos { get; set; }
        public int PedidosVencidos { get; set; }
        public int ProduccionPendiente { get; set; }
        public int InventarioFaltante { get; set; }
        public int ComprasUlt30Dias { get; set; }
        public decimal GastoComprasUlt30Dias { get; set; }
    }

    public class ReportePedidoUrgenteRow
    {
        public int PedidoId { get; set; }
        public string ClienteNombre { get; set; } = string.Empty;
        public string EstatusNombre { get; set; } = string.Empty;
        public DateTime? FechaEntregaEstimada { get; set; }
        public decimal? TotalEstimado { get; set; }
        public int DiasParaEntrega { get; set; }
        public bool EsVencido { get; set; }
    }

    public class ReporteInventarioFaltanteRow
    {
        public int InventarioId { get; set; }
        public string InventarioNombre { get; set; } = string.Empty;
        public string? UnidadNombre { get; set; }
        public decimal Disponible { get; set; }
        public decimal Requerido { get; set; }
        public decimal Faltante { get; set; }
    }

    public class ReporteProduccionPendienteRow
    {
        public int ProduccionItemId { get; set; }
        public int PedidoId { get; set; }
        public string ClienteNombre { get; set; } = string.Empty;
        public string ProductoNombre { get; set; } = string.Empty;
        public int Cantidad { get; set; }
        public string ProduccionEstatus { get; set; } = string.Empty;
        public DateTime? FechaInicio { get; set; }
        public DateTime? FechaFin { get; set; }
        public DateTime? FechaEntregaEstimada { get; set; }
        public int DiasParaEntrega { get; set; }
    }

    public class ReportesIndexViewModel
    {
        public ReportesIndexKpis Kpis { get; set; } = new();
        public IEnumerable<ReportePedidoUrgenteRow> PedidosUrgentes { get; set; } = Enumerable.Empty<ReportePedidoUrgenteRow>();
        public IEnumerable<ReporteInventarioFaltanteRow> InventarioFaltante { get; set; } = Enumerable.Empty<ReporteInventarioFaltanteRow>();
        public IEnumerable<ReporteProduccionPendienteRow> ProduccionPendiente { get; set; } = Enumerable.Empty<ReporteProduccionPendienteRow>();
    }
}