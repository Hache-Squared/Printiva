namespace ManejoPresupuestos.Models
{
    public class Pedido
    {
        public int PedidoId { get; set; }
        public int UsuarioId { get; set; }
        public int ClienteId { get; set; }
        public string ClienteNombre { get; set; }
        public int PedidoEstatusId { get; set; }
        public string EstatusNombre { get; set; }
        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaEntregaEstimada { get; set; }
        public string Notas { get; set; }
        public decimal? TotalEstimado { get; set; }
    }
}
