namespace ManejoPresupuestos.Models
{
    public class LookupItem
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = "";
    }

    public class ReporteCxcTotales
    {
        public int PedidosConSaldo { get; set; }
        public decimal? SaldoTotal { get; set; }
        public decimal? TotalCobro { get; set; }
        public decimal? TotalPagado { get; set; }
        public int PedidosVencidos { get; set; }
        public decimal? SaldoVencido { get; set; }
    }

    public class ReporteCxcBucketRow
    {
        public int BucketId { get; set; }
        public string BucketNombre { get; set; } = "";
        public int Pedidos { get; set; }
        public decimal? Saldo { get; set; }
    }

    public class ReporteCxcRow
    {
        public int PedidoId { get; set; }
        public int ClienteId { get; set; }
        public string? ClienteNombre { get; set; }

        public int PedidoEstatusId { get; set; }
        public string? PedidoEstatusNombre { get; set; }

        public DateTime PedidoFechaCreacion { get; set; }
        public DateTime? FechaEntregaEstimada { get; set; }

        public int? CotizacionId { get; set; }
        public DateTime? CotizacionFechaCreacion { get; set; }
        public DateTime? FechaVigencia { get; set; }

        public DateTime FechaBase { get; set; }
        public int DiasVencidos { get; set; }
        public int BucketId { get; set; }
        public string BucketNombre { get; set; } = "";

        public decimal TotalCobro { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal Saldo { get; set; }
        public decimal PagadoPct { get; set; }

        public DateTime? UltimoPagoFecha { get; set; }
        public string? UltimoPagoMetodo { get; set; }
        public string? UltimoPagoReferencia { get; set; }
        public string? UltimoPagoTipoNombre { get; set; }
    }

    public class ReporteCxcViewModel
    {
        // filtros
        public DateTime Desde { get; set; }
        public DateTime Hasta { get; set; }
        public int? ClienteId { get; set; }
        public int? PedidoId { get; set; }
        public bool SoloVencidos { get; set; }
        public int? BucketId { get; set; }
        public string? Metodo { get; set; }
        public decimal? MinSaldo { get; set; }

        // data
        public ReporteCxcTotales Totales { get; set; } = new();
        public List<ReporteCxcBucketRow> Buckets { get; set; } = new();
        public List<ReporteCxcRow> Rows { get; set; } = new();

        // lookups (opcional pero útil)
        public List<LookupItem> Clientes { get; set; } = new();
    }
}