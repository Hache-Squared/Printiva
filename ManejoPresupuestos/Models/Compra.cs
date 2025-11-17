using System.ComponentModel;
using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class Compra
    {
        public int CompraId { get; set; }
        public string Descripcion { get; set; }

        [Display(Name = "Tipo de compra")]
        public int CompraTipoId { get; set; }

        [Display(Name = "Tipo de filamento")]
        public int? FilamentoTipoId { get; set; }

        [Display(Name = "Categoría de compra")]
        public int CompraCategoriaId { get; set; }

        [Display(Name = "Costo total")]
        public decimal CostoTotal { get; set; }

        [Display(Name = "Fecha Creación")]
        [DataType(DataType.Date)]
        public DateTime FechaCreacion { get; set; } = DateTime.Today;

        public string CompraTipo { get; set; } = string.Empty;
        public string? FilamentoTipo { get; set; } = string.Empty;
        public string CompraCategoria { get; set; } = string.Empty;
    }
}
