using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Models
{
    public class PedidoItemCreacionViewModel
    {
        [Required]
        public int ProductoId { get; set; }

        public string ProductoNombre { get; set; }

        [Range(1, 100000)]
        public int Cantidad { get; set; } = 1;

        [Range(0, 999999999)]
        public decimal? PrecioUnitarioEstimado { get; set; }

        public string Notas { get; set; }
    }

    public class PedidoCreacionViewModel
    {
        public int PedidoId { get; set; }

        [Required]
        public int ClienteId { get; set; }

        [Required]
        public int PedidoEstatusId { get; set; }

        [DataType(DataType.Date)]
        public DateTime? FechaEntregaEstimada { get; set; }

        [StringLength(500)]
        public string Notas { get; set; }

        [Range(0, 999999999)]
        public decimal? TotalEstimado { get; set; }

        public IEnumerable<SelectListItem> Clientes { get; set; } = Enumerable.Empty<SelectListItem>();
        public IEnumerable<SelectListItem> Estatus { get; set; } = Enumerable.Empty<SelectListItem>();

        public List<PedidoItemCreacionViewModel> Items { get; set; } = new List<PedidoItemCreacionViewModel>();
    }

    public class PedidoDetallesViewModel
    {
        public Pedido Pedido { get; set; }
        public IEnumerable<PedidoItem> Items { get; set; } = Enumerable.Empty<PedidoItem>();
    }
}
